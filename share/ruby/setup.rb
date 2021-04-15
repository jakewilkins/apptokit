# frozen_string_literal: true

require 'pathname'
require 'openssl'
require 'yaml'
require 'uri'

module Apptokit
  VERSION = '0.1.0'

  RELOAD_ENV_EXIT_CODE = 234

  class ApptokitError < RuntimeError
    attr_reader :type

    def initialize(msg, type: nil)
      @type = type
      super(msg)
    end
  end

  module_function

  def config
    return @config if defined?(@config) && !block_given?

    @config = Configuration.new

    yield @config if block_given?

    @config
  end

  def config=(config)
    @config = config
  end

  def open(url, prompt: nil)
    if auto_open? && ENV.key?("BROWSER")
      `$BROWSER #{url}`
    else
      if prompt
        $stderr.puts prompt
      else
        $stderr.puts "Please open the following URL in your browser:"
      end
      $stderr.puts
      $stderr.puts url
      $stderr.puts
    end
  end

  def disable_auto_open!
    @auto_open = false
  end

  def auto_open?
    return @auto_open if defined?(@auto_open)

    true
  end
end

require 'apptokit/configuration'
require 'apptokit/config_loader'
require 'apptokit/manifest_app'
require 'apptokit/http'
