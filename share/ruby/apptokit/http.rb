# frozen_string_literal: true

require 'net/http'

module Apptokit
  module HTTP
    module_function

    def requests
      return @requests if defined?(@requests)

      @requests = []
    end

    def get(path, auth: nil, config: Apptokit.config, type: :api)
      uri = path_to_uri(path, config, type: type)

      Net::HTTP.start(uri.host, uri.port, nil, nil, nil, nil, use_ssl: uri.scheme == "https") do |http|
        req = build_request(:get, uri, config, auth)
        requests << req

        http.request(req)
      end
    end

    def post(path, body: "", headers: nil, auth: nil, config: Apptokit.config, type: :api)
      uri = path_to_uri(path, config, type: type)

      Net::HTTP.start(uri.host, uri.port, nil, nil, nil, nil, use_ssl: uri.scheme == "https") do |http|
        req = build_request(:post, uri, config, auth, additional_headers: headers || {})

        requests << req

        http.request(req, body)
      end
    end

    def path_to_uri(path, config, type:)
      return path if path.is_a?(URI)

      base_url = case type
      when :api
        config.github_api_url
      when :dotcom
        config.github_url
      end

      path = path[0] == "/" ? path : "/#{path}"

      URI("#{base_url}#{path}")
    end

    def build_request(type, uri, config, auth, additional_headers: {})
      klass = case type
      when :post
        Net::HTTP::Post
      when :get
        Net::HTTP::Get
      end

      req = klass.new(uri)
      default_headers = {}
      default_headers["User-Agent"]    = config.user_agent if config.user_agent
      default_headers["Authorization"] = auth if auth
      default_headers["Cookie"]        = config.cookie if config.cookie
      default_headers["Accept"]        = config.accept_header || "application/json"

      headers = default_headers.merge(additional_headers)
      Apptokit.config.debug do
        puts "Building #{klass} request to URI #{uri} with headers #{headers}"
      end

      headers.each do |key, value|
        req[key] = value
      end

      req
    end
  end
end
