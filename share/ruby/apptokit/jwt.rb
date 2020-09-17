# frozen_string_literal: true

require "jwt"

module Apptokit
  class JWT
    attr_accessor :token
    private :token=

    def self.generate(iat: nil, exp: nil, app_id: nil)
      new(iat: iat, exp: exp, app_id: app_id).tap { |jwt| jwt.generate }
    end

    def initialize(iat: nil, exp: nil, app_id: nil)
      @iat, @exp, @app_id = iat, exp, app_id
    end

    def header
      generate unless token
      "Bearer #{token}"
    end

    def generate
      payload = {
        iat: iat,
        exp: exp,
        iss: app_id
      }

      self.token = ::JWT.encode(payload, private_key, "RS256")
    end

    def iat
      @iat ||= Time.now.to_i
    end

    def exp
      @exp ||= Time.now.to_i + (10 * 60)
    end

    def app_id
      @app_id ||= Apptokit.config.app_id || raise(ApptokitError, "Generating a JWT requires an App ID.")
    end

    def private_key
      Apptokit.config.private_key
    end
  end
end
