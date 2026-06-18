# frozen_string_literal: true

class Session < ApplicationRecord
  TOUCH_THROTTLE = 1.minute
  IDLE_EXPIRY    = 14.days
  SUDO_DURATION  = 15.minutes

  belongs_to :user, inverse_of: :sessions

  scope :active,         -> { where("last_active_at IS NULL OR last_active_at > ?", IDLE_EXPIRY.ago) }
  scope :idle,           -> { where("last_active_at IS NOT NULL AND last_active_at <= ?", IDLE_EXPIRY.ago) }
  scope :except_current, ->(current) { where.not(id: current.id) }
  scope :by_recency,     -> { order(last_active_at: :desc) }

  def sudo?          = sudo_until.present? && sudo_until.future?
  def otp_verified?  = otp_verified_at.present?
end
