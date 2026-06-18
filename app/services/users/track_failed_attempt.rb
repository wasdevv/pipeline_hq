# frozen_string_literal: true

module Users
  class TrackFailedAttempt
    def self.call(user:, request: nil)
      user.increment!(:failed_attempts)
      Users::Lock.call(user: user, request: request) if user.failed_attempts >= User::LOCK_THRESHOLD
    end
  end
end
