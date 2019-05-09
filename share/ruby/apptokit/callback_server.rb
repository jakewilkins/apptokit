# frozen_string_literal: true

require 'webrick'

module Apptokit
  class CallbackServer
    RESPONSE_BODY = <<-HTML
    <html>
      <body>
        <h4>Sweet! You can close this window and return to your terminal</h4>
        <iframe src="https://giphy.com/embed/GYH6LraGdVAru" width="480" height="269" frameBorder="0" class="giphy-embed" allowFullScreen></iframe><p><a href="https://giphy.com/gifs/GYH6LraGdVAru">via GIPHY</a></p>
      </body>
    </html
    HTML
    attr_reader :mutex, :condition_variable, :thread, :request, :server, :port, :bind, :path, :hostname
    attr_writer :request
    private :mutex, :condition_variable, :thread, :request, :request=

    def initialize(mutex, condition_variable, &block)
      @mutex, @condition_variable = mutex, condition_variable
      @port = Apptokit.config.oauth_callback_port.nil? ? 8075 : Apptokit.config.oauth_callback_port
      @bind = Apptokit.config.oauth_callback_bind || 'localhost'
      @path = Apptokit.config.oauth_callback_path || '/callback'
      @hostname = Apptokit.config.oauth_callback_hostname || 'localhost'

      block.call(self) unless block.nil?
    end

    def callback_url
      port_part = port ? ":#{port}" : ""
      "http://#{hostname}#{port_part}/#{path}"
    end

    def oauth_code
      @oauth_code ||= Hash[URI.decode_www_form(request.query_string)]["code"]
    end
    alias callback_code oauth_code

    def start
      log_file = File.open('/dev/null', 'a+')
      log = WEBrick::Log.new(log_file)
      access_log = [
        [log_file, WEBrick::AccessLog::COMBINED_LOG_FORMAT],
      ]

      @server = WEBrick::HTTPServer.new Port: port, Bind: bind, Logger: log, AccessLog: access_log
      @server.mount_proc(path) do |req, res|
        self.request = req
        condition_variable.signal
        res["Content-Type"] = "text/html"
        res.body = RESPONSE_BODY
      end

        @thread = Thread.new do
          @server.start
        end
    end

    def shutdown
      @server.shutdown
    end
  end
end

