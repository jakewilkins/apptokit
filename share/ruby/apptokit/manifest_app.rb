# frozen_string_literal: true

require 'base64'
require 'json'
require 'apptokit/manifest_app/creator'

module Apptokit
  module ManifestApp
    CACHE_DIR = Apptokit::ConfigLoader::HOME_DIR_CONF_DIR.join("manifest_apps")

    module_function

    def load_from_cache(conf_loader)
      return [{}, :unavailable] unless cache_path(conf_loader.env).exist?

      opts = read_from_cache(conf_loader.env)

      [convert_to_apptokit_opts(opts), opts]
    end

    def create(conf_loader, cli_opts = {})
      cli_opts[:config] = conf_loader

      app_creator = ManifestApp::Creator.new(cli_opts)
      settings = app_creator.create_app

      persist_to_cache(conf_loader.env, settings)

      load_from_cache(conf_loader, cli_opts)
    end

    def install(conf_loader, cli_opts, manifest_response = nil)
      manifest_response ||= read_from_cache(conf_loader.env)

      installation_id = ManifestApp::Installer.call(
        url: manifest_response['html_url'],
        name: manifest_response['name'],
        cli_opts: cli_opts
      )

      manifest_response['installation_id'] = installation_id
      persist_to_cache(conf_loader.env, manifest_response)

      load_from_cache(conf, cli_opts)
    end

    def delete_cache(conf_loader)
      path = cache_path(conf_loader.env)
      return unless path.exist?

      FileUtils.rm(path)
    end

    # private

    def convert_to_apptokit_opts(raw_manifest)
      hash = {
        app_id:         raw_manifest["id"],
        client_id:      raw_manifest["client_id"],
        private_key:    OpenSSL::PKey::RSA.new(raw_manifest["pem"]),
        client_secret:  raw_manifest["client_secret"],
        webhook_secret: raw_manifest["webhook_secret"],
      }
      hash[:installation_id] = raw_manifest["installation_id"]

      hash
    end

    def read_from_cache(env)
      JSON.parse(Base64.decode64(File.read(cache_path(env))))
    end

    def persist_to_cache(env, settings)
      ensure_cache_dir_exists!
      File.write(cache_path(env), Base64.encode64(JSON.generate(settings)))
    end

    def delete_cache(env)
      ensure_cache_dir_exists!
      FileUtils.rm(cache_path(env)) if cache_path.exist?
    end

    def cache_path(env)
      @cache_path ||= CACHE_DIR.join("#{env}.yml")
    end

    def ensure_cache_dir_exists!
      return if @cache_dir_definitely_exists
      FileUtils.mkdir_p(CACHE_DIR) unless CACHE_DIR.exist?
      @cache_dir_definitely_exists = true
    end
  end
end
