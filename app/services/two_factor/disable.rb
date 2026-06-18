# frozen_string_literal: true

module TwoFactor
  class Disable
    def self.call(user:, request: nil)
      user.update!(otp_secret: nil, otp_enabled_at: nil, otp_backup_codes: [])
      AuthEvents::Record.call(kind: :otp_disabled, user: user, request: request)
      Result.success(:disabled, user)
    end
  end
end
