# frozen_string_literal: true

require 'webrick'

module Apptokit
  class CallbackServer
    AUTHORIZE_RESPONSE_BODY = <<-HTML
    <html>
      <head>
        <title>GitHub App Authorized</title>
        <style>
          #outer {
            width: 100%;
            /* Firefox */
            display: -moz-box;
            -moz-box-pack: center;
            -moz-box-align: center;
            /* Safari and Chrome */
            display: -webkit-box;
            -webkit-box-pack: center;
            -webkit-box-align: center;
            /* W3C */
            display: box;
            box-pack: center;
            box-align: center;
          }

          #inner {
            width: 50%;
          }
        </style>
      </head>
      <body>
        <div id="outer">
          <div id="inner">
            <h4>Sweet! You can close this window and return to your terminal</h4>
            <iframe src="https://giphy.com/embed/GYH6LraGdVAru" width="480" height="269" frameBorder="0" class="giphy-embed" allowFullScreen></iframe><p><a href="https://giphy.com/gifs/GYH6LraGdVAru">via GIPHY</a></p>
          </div>
        </div>
      </body>
    </html
    HTML

    MANIFEST_RESPONSE_BODY = <<-HTML
    <html>
      <head>
        <title>GitHub App created</title>
        <style>
          #outer {
            width: 100%;
            /* Firefox */
            display: -moz-box;
            -moz-box-pack: center;
            -moz-box-align: center;
            /* Safari and Chrome */
            display: -webkit-box;
            -webkit-box-pack: center;
            -webkit-box-align: center;
            /* W3C */
            display: box;
            box-pack: center;
            box-align: center;
          }

          #inner {
            width: 50%;
          }
        </style>
      </head>
      <body>
        <div id="outer">
          <div id="inner">
            <h4>Sweet! You can install your new app now</h4>
            <iframe src="https://giphy.com/embed/pO4UHglOY2vII" width="480" height="360" frameBorder="0" class="giphy-embed" allowFullScreen></iframe><p><a href="https://giphy.com/gifs/dancing-adventure-time-bmo-pO4UHglOY2vII">via GIPHY</a></p>
          </div>
        </div>
      </body>
    </html
    HTML

    attr_accessor :request, :port, :bind, :path, :hostname, :response
    attr_reader :mutex, :condition_variable, :thread, :server
    private :mutex, :condition_variable, :thread, :request, :request=

    def initialize(mutex, condition_variable, response: :authorize, config: nil, &block)
      config ||= Apptokit.config
      @mutex, @condition_variable = mutex, condition_variable
      @port = config.oauth_callback_port.nil? ? 8075 : config.oauth_callback_port
      @bind = config.oauth_callback_bind || 'localhost'
      @path = config.oauth_callback_path || '/callback'
      @hostname = config.oauth_callback_hostname || 'localhost'
      @response = response

      @killed = false

      block&.call(self)
    end

    def callback_url
      port_part = port ? ":#{port}" : ""
      "http://#{hostname}#{port_part}/#{path}"
    end

    def oauth_code
      return nil if request.nil?

      @oauth_code ||= Hash[URI.decode_www_form(request.query_string)]["code"]
    end
    alias code oauth_code

    def start
      setup_signal_handlers

      log_file = File.open('/dev/null', 'a+')
      log = WEBrick::Log.new(log_file)
      access_log = [
        [log_file, WEBrick::AccessLog::COMBINED_LOG_FORMAT]
      ]

      @server = WEBrick::HTTPServer.new(
        Port: port,
        Bind: bind,
        Logger: log,
        AccessLog: access_log,
        ServerName: "Apptokit Callback Server"
      )
      @server.mount_proc(path) do |req, res|
        self.request = req
        condition_variable.signal
        res["Content-Type"] = "text/html"
        res.body = response
      end

      @thread = Thread.new do
        @server.start
      end
    end

    def response
      case @response
      when :authorize
        AUTHORIZE_RESPONSE_BODY
      when :manifest
        MANIFEST_RESPONSE_BODY
      when String
        @response
      else
        "lol whoops"
      end
    end

    def shutdown
      @server.shutdown
    end

    def killed?
      @killed
    end

    def setup_signal_handlers
      Signal.trap("INT") do
        @killed = true
        shutdown
      end
    end
  end
end
