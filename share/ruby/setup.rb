# frozen_string_literal: true

require 'pathname'
require 'openssl'
require 'yaml'
require 'uri'

module Apptokit
  ApptokitError = Class.new(RuntimeError)

  class Configuration
    HOME_DIR_CONF_PATH = Pathname.new(ENV["HOME"]).join(".config/apptokit.yml")
    PROJECT_DIR_CONF_PATH = Pathname.new(Dir.pwd).join(".apptokit.yml")
    SHARE_DIR = Pathname.new(__FILE__).dirname.dirname

    YAML_OPTS = %w(
      private_key_path
      private_key_path_glob
      app_id
      webhook_secret
      installation_id
      github_url

      client_id
      client_secret
      oauth_callback_port
      oauth_callback_bind
      oauth_callback_path
      oauth_callback_hostname

      installation_keycache_expiry
      user_keycache_expiry
    )

    DEFAULT_GITHUB_URL = URI("https://api.github.com")

    attr_accessor :app_id, :webhook_secret, :installation_id
    attr_accessor :client_id, :client_secret, :oauth_callback_port, :oauth_callback_bind, :oauth_callback_path, :oauth_callback_hostname
    attr_writer :private_key_path_glob, :keycache_file_path, :env, :user_keycache_expiry, :installation_keycache_expiry

    def self.environments
      envs = []
      [HOME_DIR_CONF_PATH, PROJECT_DIR_CONF_PATH].each do |path|
        if path.exist?
          envs += (YAML.load_file(path).keys - YAML_OPTS)
        end
      end
      envs - %w(default_env)
    end

    def initialize(env = nil)
      @env = env
      reload!
    end

    def reload!
      set_opts_from_yaml(HOME_DIR_CONF_PATH)
      set_opts_from_yaml(PROJECT_DIR_CONF_PATH)
      set_opts_from_env
    end

    def private_key
      @private_key ||= begin
        unless private_key_path && !private_key_path.empty?
          raise ApptokitError.new("Private key path not set but required for using a private key.")
        end
        OpenSSL::PKey::RSA.new(File.read(private_key_path))
      end
    end

    def private_key_path=(path)
      @private_key_path = Pathname.new(path)
    end

    def private_key_path
      @private_key_path ||= Dir[private_key_path_glob].sort.last
    end

    def private_key_path_glob
      @private_key_path_glob ||= Pathname.new(Dir.pwd).join("*.pem")
    end

    def github_url=(arg)
      arg = arg[0..-2] if arg[-1] == "/"
      @github_url = URI(arg)
    end

    def github_url
      @github_url ||= DEFAULT_GITHUB_URL
    end

    def env
      @env ||= ENV["APPTOKIT_ENV"] || ENV["GH_ENV"]
    end

    def user_keycache_expiry
      @default_keycache_expiry ||= 5 * 24 * 60 * 60
    end

    def installation_keycache_expiry
      @default_keycache_expiry ||= 9 * 60
    end

    def keycache_file_path
      @keycache_file_path ||= HOME_DIR_CONF_PATH.dirname.join(".apptokit_#{env || "global"}_keycache")
    end

    private

    def set_opts_from_hash(hash)
      YAML_OPTS.each do |opt|
        if (value = hash[opt])
          send(:"#{opt}=", value)
        end
      end
    end

    def set_opts_from_yaml(path)
      return unless path.exist?

      yaml = YAML.load(path.read)
      set_opts_from_hash(yaml)

      @env = yaml["default_env"] unless env

      if env
        env_overrides = yaml[env]
        set_opts_from_hash(env_overrides) if env_overrides
      end
    end

    def set_opts_from_env
      set_opts_from_hash(YAML_OPTS.each_with_object({}) do |opt, out|
        out[opt] = ENV["APPTOKIT_#{opt.upcase}"]
      end)
    end
  end

  module_function

  def config
    return @config if defined?(@config) && !block_given?

    @config = Configuration.new

    yield @config if block_given?

    @config
  end
end

