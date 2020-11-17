# frozen_string_literal: true

require 'base64'
require 'json'
require 'apptokit/manifest_app/creator'
require 'apptokit/manifest_app/installer'

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

      load_from_cache(conf_loader)
    end

    def install(conf_loader, _cli_opts, manifest_response = nil)
      manifest_response ||= read_from_cache(conf_loader.env)

      return manifest_response['installation_id'] if manifest_response['installation_id']

      installation_id = ManifestApp::Installer.call(
        url: manifest_response['html_url'],
        name: manifest_response['name'],
        conf_loader: conf_loader
      )

      manifest_response['installation_id'] = installation_id
      persist_to_cache(conf_loader.env, manifest_response)

      opts, = load_from_cache(conf_loader)
      opts['installation_id']
    end

    def delete_cache(config_loader)
      ensure_cache_dir_exists!
      path = cache_path(config_loader.env)
      FileUtils.rm(path) if path.exist?
    end

    def convert_to_apptokit_opts(raw_manifest)
      key = begin
        OpenSSL::PKey::RSA.new(raw_manifest["pem"])
      rescue OpenSSL::PKey::RSAError # rubocop:disable Layout/RescueEnsureAlignment
        :unavailable
      end
      hash = {
        "app_id"         => raw_manifest["id"],
        "client_id"      => raw_manifest["client_id"],
        "private_key"    => key,
        "client_secret"  => raw_manifest["client_secret"],
        "webhook_secret" => raw_manifest["webhook_secret"]
      }
      hash["installation_id"] = raw_manifest["installation_id"] if raw_manifest["installation_id"]

      hash
    end

    def read_from_cache(env)
      JSON.parse(Base64.decode64(File.read(cache_path(env))))
    end

    def persist_to_cache(env, settings)
      ensure_cache_dir_exists!
      File.write(cache_path(env), Base64.encode64(JSON.generate(settings)))
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
