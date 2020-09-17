# frozen_string_literal: true

require 'base64'
require 'json'
require 'apptokit/manifest_app'

module Apptokit
  class ManifestApp::Settings
    CACHE_DIR = Configuration::HOME_DIR_CONF_DIR.join("manifest_apps")

    def self.fetch(gh_env, yaml_conf, **cli_opts)
      new(gh_env, yaml_conf, *cli_opts).fetch
    end

    attr_reader :gh_env, :yaml_conf, :cli_opts, :app_settings, :app_owner

    def initialize(gh_env, yaml_conf, app_owner, **cli_opts)
      @gh_env, @yaml_conf, @app_owner, @cli_opts = gh_env, yaml_conf, app_owner, cli_opts
      @app_settings = nil
      @loaded = false
      @manifest_app = nil
      load_from_cache
    end

    def fetch
      ensure_cache_dir_exists!

      load_from_cache unless cli_opts[:skip_cache]
      return self if loaded?

      opts = {
        env_name: gh_env,
        yaml_conf: yaml_conf,
        app_owner: app_owner
      }.merge(cli_opts)
      @manifest_app = ManifestApp.new(opts)
      settings = @manifest_app.create_app
      persist_to_cache(settings)
      load_from_cache

      self
    end

    def apply(conf)
      conf.app_id         = app_settings["id"]
      conf.client_id      = app_settings["client_id"]
      conf.private_key    = OpenSSL::PKey::RSA.new(app_settings["pem"])
      conf.client_secret  = app_settings["client_secret"]
      conf.webhook_secret = app_settings["webhook_secret"]

      conf.installation_id = app_settings["installation_id"] unless conf.installation_id

      conf
    end

    def install_app
      return unless loaded?
      return if skip_app_installation?

      ENV["INSTALLING_APP"] = "true"

      install_url = "#{app_settings['html_url']}/installations/new"
      `$BROWSER #{install_url}`

      sleep 2

      installation, token = nil
      count = 0
      begin
        count += 1
        installations, token = get_installations(token)

        installation = installations.first
        sleep 2 unless installation
      end while !installation && count < 10

      unless installation
        app_name = app_settings["name"] || generated_name
        $stderr.puts "Unable to retrieve an installation id for #{app_name}."
        $stderr.puts "Please install #{app_name} manually and update your apptokit.yml with the installation id."
        exit 17
      end

      app_settings["installation_id"] = installation["id"]
      persist_to_cache(app_settings)
    end

    def load_from_cache
      return unless cache_path.exist?

      @app_settings = JSON.parse(Base64.decode64(File.read(cache_path)))
      @loaded = true
    end

    def persist_to_cache(settings)
      File.write(cache_path, Base64.encode64(JSON.generate(settings)))
    end

    def delete_cache
      FileUtils.rm(cache_path) if cache_path.exist?
    end

    def loaded?
      @loaded
    end

    def cache_path
      @cache_path ||= CACHE_DIR.join("#{gh_env}.yml")
    end

    def ensure_cache_dir_exists!
      FileUtils.mkdir_p(CACHE_DIR) unless CACHE_DIR.exist?
    end

    def get_installations(token = nil)
      token ||= Apptokit::JWT.new.header
      uri = URI("#{Apptokit.config.github_api_url}/app/installations")
      # puts "fetching installations #{uri}"
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        req = Net::HTTP::Get.new(uri)
        req["Accept"] = "application/vnd.github.machine-man-preview+json"
        req["Authorization"] = token

        http.request(req)
      end

      case response
      when Net::HTTPSuccess
        parsed = JSON.parse(response.body)

        [parsed, token]
      else
        sleep 0.1

        [[], token]
      end
    end

    def skip_app_installation?
      ENV.has_key?("SKIP_INSTALLATION")
    end
  end
end
