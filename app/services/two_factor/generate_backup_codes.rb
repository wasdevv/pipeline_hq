# frozen_string_literal: true

module TwoFactor
  class GenerateBackupCodes
    COUNT = User::BACKUP_CODE_COUNT

    def self.call
      COUNT.times.map { SecureRandom.hex(4) } # 8 hex chars
    end
  end
end
