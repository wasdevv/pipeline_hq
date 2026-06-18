# frozen_string_literal: true

module Passwords
  class BreachCheck
    TIMEOUT_SECONDS = 1

    def self.call(password)
      Pwned::Password.new(password, request_options: { read_timeout: TIMEOUT_SECONDS, open_timeout: TIMEOUT_SECONDS }).pwned?
    rescue Pwned::Error, Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.warn("Pwned check unavailable: #{e.class}")
      false
    end
  end
end
