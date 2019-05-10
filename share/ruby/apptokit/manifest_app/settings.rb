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

    attr_reader :gh_env,  :yaml_conf, :cli_opts, :app_settings

    def initialize(gh_env, yaml_conf, **cli_opts)
      @gh_env, @yaml_conf, @cli_opts = gh_env, yaml_conf, cli_opts
      @app_settings = nil
      @loaded = false
      load_from_cache
    end

    def fetch
      ensure_cache_dir_exists!

      load_from_cache unless cli_opts[:skip_cache]
      return self if loaded?

      opts = {env_name: gh_env, yaml_conf: yaml_conf}.merge(cli_opts)
      app = ManifestApp.new(opts)
      settings = app.create_app
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

      unless conf.installation_id
        conf.installation_id = app_settings["installation_id"]
      end

      conf
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
  end
end
