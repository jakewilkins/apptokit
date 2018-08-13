# frozen_string_literal: true

require 'net/http'
require 'thread'

require 'apptokit/key_cache'
require 'apptokit/oauth_callback_server'

module Apptokit
  class UserToken
    def self.generate(auto_open: true, code: nil, skip_cache: false)
      new(auto_open: auto_open, code: code, skip_cache: skip_cache).tap {|t| t.generate}
    end

    attr_reader :auto_open, :installation_id, :mutex, :condition_variable, :skip_cache
    attr_accessor :token, :token_type, :cached
    private :token=, :token_type=, :cached=

    def initialize(installation_id: nil, auto_open: true, code: nil, skip_cache: false)
      @installation_id = installation_id || Apptokit.config.installation_id
      @auto_open = auto_open.nil? ? true : auto_open
      @code = code
      @cached = true
      @skip_cache = skip_cache
      @mutex, @condition_variable = Mutex.new, ConditionVariable.new
    end

    def header
      generate unless token
      "token #{token}"
    end

    def generate
      if skip_cache
        self.cached = false
        return perform_generation
      end

      token = Apptokit.keycache.get_set(cache_key, :user) do
        self.cached = false
        perform_generation.token
      end

      if self.cached
        self.token = token
        self.token_type = "Bearer"
      end

      self
    end

    def client_id
      Apptokit.config.client_id
    end

    def client_secret
      Apptokit.config.client_secret
    end

    private

    def perform_generation
      validate_generateable!

      oauth_code = generate_oauth_code

      token_info = exchange_code_for_token(oauth_code)
      self.token = token_info["access_token"]
      self.token_type = token_info["token_type"]
      self
    end

    def cache_key
      "user:#{installation_id}"
    end

    def generate_oauth_code
      return @code if @code

      callback_server = OauthCallbackServer.new(mutex, condition_variable)
      callback_server.start

      if auto_open
        `$BROWSER #{oauth_url(callback_server.callback_url)}`
      else
        puts "Please open the link below to continue authorizing application:\n\n  #{oauth_url(callback_server.callback_url)}\n\n"
      end

      mutex.synchronize { condition_variable.wait(mutex, 60) }
      callback_server.shutdown

      unless callback_server.oauth_code
        raise ApptokitError.new(
          "Failed to get an OAuth Code from GitHub, did you visit the URL in your browser?"
        )
      end

      callback_server.oauth_code
    end

    def exchange_code_for_token(code)
      uri = URI("#{Apptokit.config.github_url.to_s.gsub("api.", "")}/login/oauth/access_token?")

      res = Net::HTTP.post_form(uri, "client_id" => client_id,
                "client_secret" => client_secret, "code" => code)

      case res
      when Net::HTTPSuccess
        Hash[URI.decode_www_form(res.body)]
      else
        raise ApptokitError.new("Failed to exchange OAuth code for token: #{res.code}\n\n#{res.body}")
      end
    end

    def oauth_url(callback_url)
      @oauth_url ||= "#{Apptokit.config.github_url.to_s.gsub("api.", "")}/login/oauth/authorize?client_id=#{client_id}&callback_url=#{callback_url}"
    end

    def validate_generateable!
      missing = []
      missing << "client_id" unless client_id
      missing << "client_secret" unless client_secret

      unless missing.empty?
        raise ApptokitError.new("Cannot create a User Token without: #{missing.join(", ")}.")
      end
    end
  end
end
