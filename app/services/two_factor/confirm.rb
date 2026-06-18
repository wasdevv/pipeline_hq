# frozen_string_literal: true

module TwoFactor
  class Confirm
    def self.call(user:, secret:, code:, request: nil)
      unless ROTP::TOTP.new(secret).verify(code.to_s, drift_behind: 30)
        return Result.failure(:invalid_code)
      end

      codes = TwoFactor::GenerateBackupCodes.call

      user.update!(
        otp_secret:       secret,
        otp_enabled_at:   Time.current,
        otp_backup_codes: codes.map { |c| BCrypt::Password.create(c).to_s }
      )
      AuthEvents::Record.call(kind: :otp_enrolled, user: user, request: request)

      Result.success(:enrolled, codes)
    end
  end
end
