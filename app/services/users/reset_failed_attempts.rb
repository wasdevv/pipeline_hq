# frozen_string_literal: true

module Users
  class ResetFailedAttempts
    def self.call(user:)
      return if user.failed_attempts.zero? && user.locked_at.nil?

      user.update!(failed_attempts: 0, locked_at: nil)
    end
  end
end
