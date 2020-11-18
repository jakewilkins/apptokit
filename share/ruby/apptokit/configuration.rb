# frozen_string_literal: true

module Apptokit
  class Configuration
    SHARE_DIR = Pathname.new(__FILE__).dirname.dirname.dirname

    YAML_OPTS = %w(
      private_key_path
      private_key_path_glob
      app_id
      webhook_secret
      installation_id
      github_url
      github_api_url

      client_id
      client_secret
      oauth_callback_port
      oauth_callback_bind
      oauth_callback_path
      oauth_callback_hostname

      installation_keycache_expiry
      user_keycache_expiry

      personal_access_token

      manifest_url
      manifest
      app_owner

      user_agent
      cookie
      accept_header
    ).freeze

    DUMPABLE_OPTIONS = %w(
      github_url
      github_api_url

      app_id
      installation_id

      private_key_path

      webhook_secret

      client_id
      client_secret

      installation_keycache_expiry
      user_keycache_expiry

      personal_access_token

      user_agent
      cookie
      accept_header
    ).freeze

    DEFAULT_GITHUB_URL     = URI("https://github.com")
    DEFAULT_GITHUB_API_URL = URI("https://api.github.com")

    attr_reader :env

    def initialize(env = nil, loader = nil)
      @env = env
      loader ||= ConfigLoader.new
      load_env(loader)
    end

    def load_env(config_loader)
      config_loader.load!

      YAML_OPTS.each do |attr|
        value = config_loader.fetch(attr)
        send(:"#{attr}=", value) if value
      end

      @env = config_loader.env

      return unless (pem = config_loader.fetch("private_key"))

      @private_key = pem
    end

    def private_key
      @private_key ||= begin
        raise ApptokitError, "Private key path not set but required for using a private key." unless private_key_path && !private_key_path.to_s.empty?

        OpenSSL::PKey::RSA.new(File.read(private_key_path))
      rescue OpenSSL::PKey::RSAError # rubocop:disable Layout/RescueEnsureAlignment
        :unavailable
      end
    end

    def private_key_path=(path)
      @private_key_path = Pathname.new(path)
    end

    def private_key_path
      @private_key_path ||= Dir[private_key_path_glob].max
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

    def github_api_url=(arg)
      arg = arg[0..-2] if arg[-1] == "/"
      @github_api_url = URI(arg)
    end

    def github_api_url
      @github_api_url ||= DEFAULT_GITHUB_API_URL
    end

    def user_keycache_expiry
      @user_keycache_expiry ||= 5 * 24 * 60 * 60
    end

    def installation_keycache_expiry
      @installation_keycache_expiry ||= 9 * 60
    end

    def user_agent
      @user_agent ||= "Apptokit #{Apptokit::VERSION}"
    end

    def accept_header
      @accept_header ||= "application/vnd.github.v3.text-match+json"
    end

    def keycache_file_path
      @keycache_file_path ||= ConfigLoader::HOME_DIR_CONF_DIR.join(".apptokit_#{env || 'global'}_keycache")
    end

    def debug(msg = nil, &block)
      return unless debug?
      return block.call if block

      $stderr.puts msg
    end

    # This avoids overwriting methods and generating warnings
    YAML_OPTS.each do |attr|
      attr_reader attr unless method_defined?(attr)
      attr_writer attr unless method_defined?(:"#{attr}=")
    end
    private(*YAML_OPTS.map { |s| "#{s}=".intern }) # rubocop:disable Style/AccessModifierDeclarations

    private

    def debug?
      ENV.key?("DEBUG")
    end
  end
end
