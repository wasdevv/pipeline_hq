# frozen_string_literal: true

module AuthenticationHelpers
  TEST_PASSWORD = "TestUser!2026PipelineHQ"

  def sign_in_as(user, password: TEST_PASSWORD)
    post session_url, params: { email_address: user.email_address, password: password }
  end

  def confirm_email_for(user)
    user.update!(confirmed_at: Time.current)
    user
  end

  def with_2fa(user)
    user.update!(
      otp_secret:     ROTP::Base32.random,
      otp_enabled_at: Time.current
    )
    user
  end

  def lock_out(user)
    user.update!(
      failed_attempts: User::LOCK_THRESHOLD,
      locked_at:       Time.current
    )
    user
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers
end
