# frozen_string_literal: true

module TwoFactor
  class RegenerateBackupCodes
    def self.call(user:, request: nil)
      codes = GenerateBackupCodes.call
      user.update!(otp_backup_codes: codes.map { |c| BCrypt::Password.create(c).to_s })
      AuthEvents::Record.call(kind: :backup_codes_regenerated, user: user, request: request)
      Result.success(:regenerated, codes)
    end
  end
end
