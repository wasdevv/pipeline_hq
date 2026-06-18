# frozen_string_literal: true

module Users
  class Lock
    def self.call(user:, request: nil)
      user.update!(locked_at: Time.current)
      AuthEvents::Record.call(kind: :account_locked, user: user, request: request,
                              metadata: { failed_attempts: user.failed_attempts })
    end
  end
end
