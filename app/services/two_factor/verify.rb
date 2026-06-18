# frozen_string_literal: true

module TwoFactor
  class Verify
    def self.call(user:, code:, request: nil)
      code = code.to_s.strip

      if ROTP::TOTP.new(user.otp_secret).verify(code, drift_behind: 30)
        AuthEvents::Record.call(kind: :otp_verified, user: user, request: request)
        return Result.success(:verified, user)
      end

      consumed = consume_backup_code(user, code)
      if consumed
        AuthEvents::Record.call(kind: :backup_code_used, user: user, request: request)
        return Result.success(:verified, user)
      end

      AuthEvents::Record.call(kind: :otp_failed, user: user, request: request)
      Result.failure(:invalid_code)
    end

    def self.consume_backup_code(user, code)
      remaining = []
      matched = false
      user.otp_backup_codes.each do |hash|
        if !matched && BCrypt::Password.new(hash) == code
          matched = true
        else
          remaining << hash
        end
      end
      user.update!(otp_backup_codes: remaining) if matched
      matched
    end
    private_class_method :consume_backup_code
  end
end
