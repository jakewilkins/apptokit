# frozen_string_literal: true

require 'apptokit/jwt'
require 'net/http'
require 'json'

module Apptokit
  class InstallationToken
    def self.generate(installation_id: nil)
      new(installation_id: installation_id).tap {|t| t.generate}
    end

    attr_reader :installation_id, :token, :expires_at
    attr_writer :token, :expires_at
    private :token=, :expires_at=

    def initialize(installation_id: nil)
      @installation_id = installation_id || Apptokit.config.installation_id
    end

    def header
      generate unless token
      "token #{token}"
    end

    def generate
      uri = URI(installation_token_url)
      request = Net::HTTP::Post.new(uri)
      request["Accept"] = "application/vnd.github.machine-man-preview+json"
      request["Authorization"] = jwt.header

      response = Net::HTTP.start(uri.hostname, uri.port, nil, nil, nil, nil, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      case response
      when Net::HTTPSuccess then
        hash = JSON.parse(response.body)
        self.token      = hash["token"]
        self.expires_at = hash["expires_at"]
      else
        raise ApptokitError.new("Could not create an Installation Token: #{response.code}\n\n#{response.body}")
      end
      self
    end

    def jwt
      @jwt ||= JWT.generate
    end

    def installation_token_url
      URI("#{Apptokit.config.github_url}/installations/#{installation_id}/access_tokens")
    end
  end
end
