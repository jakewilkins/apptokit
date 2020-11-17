# frozen_string_literal: true

module Apptokit
  module ManifestApp
    module Installer
      module_function

      def call(url:, name:, conf_loader:)
        return if skip_app_installation?

        ENV["INSTALLING_APP"] = "true"

        install_url = "#{url}/installations/new"
        Apptokit.open(install_url)

        sleep 2

        installation = nil
        count = 0

        Apptokit.config = Apptokit::Configuration.new(conf_loader.env, conf_loader)
        token = get_token(conf_loader)
        installation_uri = URI("#{Apptokit.config.github_api_url}/app/installations")

        loop do
          count += 1
          installations = get_installations(token, installation_uri)

          installation = installations.first
          sleep 2 unless installation

          break if installation
          break if count > 10
        end

        unless installation
          app_name = name || "your app"
          $stderr.puts "Unable to retrieve an installation id for #{app_name}."
          $stderr.puts "Please install #{app_name} manually and update your apptokit.yml with the installation id."
          exit 17
        end

        installation["id"]
      end

      def get_installations(token, uri)
        # puts "fetching installations #{uri}"
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          req = Net::HTTP::Get.new(uri)
          req["User-Agent"] = Apptokit.config.user_agent
          req["Authorization"] = token

          http.request(req)
        end

        case response
        when Net::HTTPSuccess
          parsed = JSON.parse(response.body)

          parsed
        else
          sleep 0.1

          []
        end
      end

      def get_token(_conf_loader)
        Apptokit::JWT.new.header
      end

      def skip_app_installation?
        ENV.key?("SKIP_INSTALLATION")
      end
    end
  end
end
