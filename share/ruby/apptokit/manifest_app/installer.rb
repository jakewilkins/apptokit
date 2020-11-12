# frozen_string_literal: true

module Apptokit
  module ManifestApp
    module Installer
      module_function

      def call(url:, name:)
        return if skip_app_installation?

        ENV["INSTALLING_APP"] = "true"

        install_url = "#{url}/installations/new"
        Apptokit.open(install_url)

        sleep 2

        installation, token = nil
        count = 0
        loop do
          count += 1
          installations, token = get_installations(token)

          installation = installations.first
          sleep 2 unless installation

          break if !installation && count < 10
        end

        unless installation
          app_name = name || "your app"
          $stderr.puts "Unable to retrieve an installation id for #{app_name}."
          $stderr.puts "Please install #{app_name} manually and update your apptokit.yml with the installation id."
          exit 17
        end

        installation["id"]
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
        ENV.key?("SKIP_INSTALLATION")
      end

    end
  end
end
