# frozen_string_literal: true

require 'dbm'

module Apptokit
  class KeyCache
    attr_reader :db

    def initialize
      @db = DBM.open(db_file_path, 0600, DBM::WRCREAT)
    end

    def keys
      db.keys
    end

    def get(key, ignore_expiry: false, return_expiry: false)
      value = db[key]
      return value unless value

      value, expiry = value.split(":::")
      expiry = DateTime.iso8601(expiry)

      if !ignore_expiry && DateTime.now > expiry
        drop(key)
        nil
      else
        if return_expiry
          [value, expiry]
        else
          value
        end
      end
    end

    def set(key, value, expiry, return_expiry: false)
      db[key] = "#{value}:::#{format_expiration(expiry)}"

      if return_expiry
        [value, expiry]
      else
        value
      end
    end

    def get_set(key, expiry, return_expiry: false, &block)
      value = get(key, return_expiry: return_expiry)
      return value if value

      value, returned_expiry = block.call

      set(key, value, returned_expiry || expiry, return_expiry: returned_expiry)
    end

    def drop(key)
      db.delete(key)
    end

    def clear
      db.clear
    end

    private

    def format_expiration(expiry, iso8601: true)
      expiry = case expiry
      when String
        DateTime.iso8601(expiry)
      when Numeric
        Time.now + expiry
      when DateTime, Time, Date
        expiry.to_datetime
      when :user
        format_expiration(Apptokit.config.user_keycache_expiry, iso8601: false)
      when :installation
        format_expiration(Apptokit.config.installation_keycache_expiry, iso8601: false)
      end
      iso8601 ? expiry.iso8601 : expiry
    end

    def db_file_path
      Apptokit.config.keycache_file_path
    end
  end

  def self.keycache
    @keycache ||= KeyCache.new
  end
end
