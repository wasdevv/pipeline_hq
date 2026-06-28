# frozen_string_literal: true

class UserDashboardPreference < ApplicationRecord
  SECTIONS = %w[
    stats
    nav_accounts
    nav_contacts
    nav_deals
    nav_audit
    recent_events
    auth_activity
  ].freeze

  belongs_to :user, inverse_of: :dashboard_preferences

  validates :section, presence: true, inclusion: { in: SECTIONS },
            uniqueness: { scope: :user_id }
  validates :enabled, inclusion: { in: [ true, false ] }
  validates :position, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
end
