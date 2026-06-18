# frozen_string_literal: true

module Users
  class Confirm
    def self.call(token:, request: nil)
      user = User.find_by_token_for(:email_confirmation, token)

      if user.nil?
        AuthEvents::Record.call(kind: :email_confirmation_failed, request: request, metadata: { reason: "invalid_or_expired" })
        return Result.failure(:invalid_token)
      end

      if user.confirmed?
        return Result.success(:already_confirmed, user)
      end

      user.update!(confirmed_at: Time.current)
      AuthEvents::Record.call(kind: :email_confirmed, user: user, request: request)

      Result.success(:confirmed, user)
    end
  end
end
