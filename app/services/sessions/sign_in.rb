# frozen_string_literal: true

module Sessions
  class SignIn
    def self.call(...) = new(...).call

    def initialize(email_address:, password:, request:)
      @email_address = email_address
      @password      = password
      @request       = request
    end

    def call
      user = User.authenticate_by(email_address: @email_address, password: @password)

      unless user
        track_failed_lookup
        return Result.failure(:invalid_credentials)
      end

      return Result.failure(:locked)       if user.locked?
      return Result.failure(:unconfirmed)  if !user.confirmed?

      if user.otp_enabled?
        return Result.success(:requires_otp, user)
      end

      Users::ResetFailedAttempts.call(user: user)
      AuthEvents::Record.call(kind: :login_success, user: user, request: @request)
      Result.success(:signed_in, user)
    end

    private

    def track_failed_lookup
      user = User.find_by(email_address: @email_address.to_s.strip.downcase)
      Users::TrackFailedAttempt.call(user: user, request: @request) if user
      AuthEvents::Record.call(
        kind:          :login_failed,
        user:          user,
        email_address: @email_address,
        request:       @request
      )
    end
  end
end
