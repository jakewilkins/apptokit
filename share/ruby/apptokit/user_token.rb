# frozen_string_literal: true

require 'net/http'
require 'apptokit/key_cache'
require 'apptokit/callback_server'

module Apptokit
  class UserToken
    def self.generate(auto_open: true, code: nil, force: false, user: nil)
      new(auto_open: auto_open, code: code, skip_cache: force, user: user).tap(&:generate)
    end

    def self.refresh(token:)
      new(refresh_token: token).tap(&:refresh)
    end

    def self.get_code(auto_open: true, user: nil)
      new(auto_open: auto_open, user: user).tap(&:get_code)
    end

    attr_reader :auto_open, :installation_id, :mutex, :condition_variable, :skip_cache, :user, :oauth_code
    attr_accessor :token, :token_type, :cached, :refresh_token, :expires_in, :refresh_token_expires_in, :error_description
    private :token=, :token_type=, :cached=

    def initialize(installation_id: nil, auto_open: true, code: nil, skip_cache: false, user: nil, refresh_token: nil)
      @installation_id = installation_id || Apptokit.config.installation_id
      @auto_open = auto_open.nil? ? true : auto_open
      @oauth_code = code
      @refresh_token = refresh_token
      @cached = true
      @skip_cache = skip_cache
      @user = user
      @mutex, @condition_variable = Mutex.new, ConditionVariable.new
    end

    def header
      generate unless token
      "token #{token}"
    end

    def generate
      if skip_cache
        self.cached = false
        perform_generation
        Apptokit.keycache.set(cache_key, cache_value, :user)
        return self
      end

      token = Apptokit.keycache.get_set(cache_key, :user) do
        self.cached = false
        perform_generation
        cache_value
      end

      load_from(cache: token) if cached

      self
    end

    def refresh
      refresh_token || load_from(cache: true)

      token_info = exchange_code_for_token(refresh_token, refresh: true)
      load_from(response: token_info)

      Apptokit.keycache.set(cache_key, cache_value, :user)

      self
    end

    def get_code
      generate_oauth_code
    end

    def client_id
      Apptokit.config.client_id
    end

    def client_secret
      Apptokit.config.client_secret
    end

    def user_agent
      Apptokit.config.user_agent
    end

    def cookie
      Apptokit.config.cookie
    end

    def success?
      !error?
    end

    def error?
      !error_description.nil?
    end

    private

    def perform_generation
      validate_generateable!

      oauth_code = generate_oauth_code

      token_info = exchange_code_for_token(oauth_code)
      load_from(response: token_info)
      self
    end

    def cache_key
      "user:#{installation_id}:#{user}"
    end

    def generate_oauth_code
      return @oauth_code if @oauth_code

      callback_server = CallbackServer.new(mutex, condition_variable)
      callback_server.start

      Apptokit.open(
        oauth_url(callback_server.callback_url),
        prompt: "Please open the link below to continue authorizing application:"
      )

      begin
        mutex.synchronize { condition_variable.wait(mutex, 60) }
      rescue Interrupt
        puts "bye!"
        exit!
      ensure
        begin
          callback_server.shutdown
        rescue StandardError
          nil
        end
      end

      raise ApptokitError, "Failed to get an OAuth Code from GitHub, did you visit the URL in your browser?" unless callback_server.oauth_code

      @oauth_code = callback_server.oauth_code
    end

    def exchange_code_for_token(code, refresh: false)
      key = refresh ? "refresh_token" : "code"

      body = {
        "client_id"     => client_id,
        "client_secret" => client_secret,
        key             => code
      }
      body["grant_type"] = "refresh_token" if refresh

      res = HTTP.post(
        "/login/oauth/access_token",
        body: URI.encode_www_form(body),
        headers: { "Content-Type" => "application/x-www-form-urlencoded", "Accept" => "*/*" },
        type: :dotcom
      )

      case res
      when Net::HTTPSuccess
        Hash[URI.decode_www_form(res.body)]
      when Net::HTTPRedirection
        Apptokit.config.debug do
          p res, res.uri, body
          puts "Redirected to #{res['Location']}"
          puts res.each.map { |h, k| "#{h} => #{k}" }.join("\n")
        end
        raise ApptokitError, "Redirected during token create, possibly a cookie issue? Location: #{res['Location']}"
      else
        raise ApptokitError, "Failed to exchange OAuth code for token: #{res.code}\n\n#{res.body}"
      end
    end

    def oauth_url(callback_url)
      @oauth_url ||= begin
        login_value = user.nil? ? "" : "&login=#{user}"
        "#{Apptokit.config.github_url}/login/oauth/authorize?client_id=#{client_id}#{login_value}&callback_url=#{callback_url}"
      end
    end

    def validate_generateable!
      missing = []
      missing << "client_id" unless client_id
      missing << "client_secret" unless client_secret

      raise ApptokitError, "Cannot create a User Token without: #{missing.join(', ')}." unless missing.empty?
    end

    def load_from(response: nil, cache: nil)
      if response
        self.token = response["access_token"]
        self.token_type = response["token_type"]
        self.expires_in = response["expires_in"]
        self.refresh_token = response["refresh_token"]
        self.refresh_token_expires_in = response["refresh_token_expires_in"]
        self.error_description = response["error_description"]
      end

      cache = Apptokit.keycache.get(cache_key) if cache == true
      return nil unless cache

      token, refresh_token = cache.split("-")
      self.token = token
      self.refresh_token = refresh_token
      self.token_type = "Bearer"
    end

    def cache_value
      "#{token}-#{refresh_token}"
    end
  end
end
