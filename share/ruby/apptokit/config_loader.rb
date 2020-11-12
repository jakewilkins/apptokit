# frozen_string_literal: true

require 'pathname'
require 'openssl'
require 'yaml'
require 'uri'

module Apptokit
  class ConfigLoader
    HOME_DIR_CONF_PATH = Pathname.new(ENV["HOME"]).join(".config/apptokit.yml")
    HOME_DIR_CONF_DIR = Pathname.new(ENV["HOME"]).join(".config/apptokit")
    PROJECT_DIR_CONF_PATH = Pathname.new(Dir.pwd).join(".apptokit.yml")

    def self.environments
      envs = []
      [HOME_DIR_CONF_PATH, PROJECT_DIR_CONF_PATH].each do |path|
        envs += (YAML.load_file(path).keys - Apptokit::Configuration::YAML_OPTS) if path.exist?
      end
      (envs - %w(default_env)).reject { |e| /_defaults/.match?(e) }
    end

    def self.loading_manifest(&block)
      if block
        @loading_manifest = true
        block.call
        @loading_manifest = false
      else
        @loading_manifest ||= nil
      end
    end

    attr_reader :config, :manifest_data
    private :config

    def initialize(env = nil)
      @env = env
      @config = {}
    end

    def read_from_env!

    end

    def load!
      set_opts_from_yaml(HOME_DIR_CONF_PATH)
      set_opts_from_yaml(PROJECT_DIR_CONF_PATH)
      set_opts_from_cached_manifest
      set_opts_from_env
    end

    def fetch(var, default = nil, &block)
      # puts "fetching #{var}"
      if respond_to?(var.intern)
        send(var.intern)
      else
        config.fetch(var, default, &block)
      end
    end

    def set(attr, value)
      config[attr.intern] = value
    end

    def env
      config['env'] ||= ENV["APPTOKIT_ENV"] || ENV["GH_ENV"]
    end

    def keycache_file_path
      config['keycache_file_path'] ||= HOME_DIR_CONF_DIR.join(".apptokit_#{env || 'global'}_keycache")
    end

    def env_from_manifest?
      config['manifest_url'].present? || !manifest_data.nil?
    end

    def clear_manifest_cache!
      ManifestApp.delete_cache(self)
    end

    def debug(msg = nil, &block)
      return unless debug?
      return block.call if block

      $stderr.puts msg
    end

    def to_shell

    end

    private

    def set_opts_from_hash(hash)
      Apptokit::Configuration::YAML_OPTS.each do |opt|
        if (value = hash[opt])
          if respond_to?(:"#{opt}=")
            send(:"#{opt}=", value)
          else
            config[opt] = value
          end
        end
      end
    end

    def set_opts_from_yaml(path)
      return unless path.exist?

      yaml = YAML.safe_load(path.read, aliases: true)
      set_opts_from_hash(yaml)

      @env = yaml["default_env"] unless env

      return unless env

      env_overrides = yaml[env]
      set_opts_from_hash(env_overrides) if env_overrides
    end

    def set_opts_from_cached_manifest
      manifest_settings, raw_config = ManifestApp.load_from_cache(self)

      unless raw_config == :unavailable
        @config = @config.merge(manifest_settings)
        @manifest_data = raw_config
      end
    end

    def set_opts_from_env
      set_opts_from_hash(Apptokit::Configuration::YAML_OPTS.each_with_object({}) do |opt, out|
        out[opt] = ENV["APPTOKIT_#{opt.upcase}"]
      end)
    end

    def realize_manifest?
      !ENV.key?("LIMITED_MANIFEST")
    end

    def installing_app?
      ENV.key?("INSTALLING_APP")
    end

    def debug?
      ENV.key?("DEBUG")
    end
  end
end
