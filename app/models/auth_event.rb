# frozen_string_literal: true

class AuthEvent < ApplicationRecord
  KINDS = %w[
    signup
    email_confirmation_sent email_confirmation_failed email_confirmed
    login_success login_failed
    account_locked account_auto_unlocked
    password_reset_requested password_reset_completed
    otp_enrolled otp_disabled otp_verified otp_failed
    backup_code_used backup_codes_regenerated
    session_revoked sessions_revoked_all
    sudo_started honeypot_triggered
  ].freeze

  self.inheritance_column = nil

  belongs_to :user, optional: true, inverse_of: :auth_events

  validates :kind, presence: true, inclusion: { in: KINDS }

  scope :recent, -> { order(created_at: :desc) }
end
