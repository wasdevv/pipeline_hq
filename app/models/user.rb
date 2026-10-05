# frozen_string_literal: true

class User < ApplicationRecord
  LOCK_THRESHOLD = 5
  LOCK_DURATION  = 15.minutes
  BACKUP_CODE_COUNT = 8

  has_secure_password
  has_many :sessions,      dependent: :destroy
  has_many :auth_events,   dependent: :nullify, inverse_of: :user
  has_many :domain_events, class_name: "DomainEvent", foreign_key: :actor_id,
           dependent: :nullify, inverse_of: :actor

  has_many :workspace_memberships, dependent: :destroy, inverse_of: :user
  has_many :workspaces, through: :workspace_memberships
  has_many :conversation_participants, dependent: :destroy, inverse_of: :user
  has_many :conversations, through: :conversation_participants
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id,
           dependent: :nullify, inverse_of: :sender
  has_many :chat_sessions, dependent: :destroy, inverse_of: :user
  has_many :dashboard_preferences, class_name: "UserDashboardPreference",
           dependent: :destroy, inverse_of: :user
  has_many :owned_workspaces, class_name: "Workspace", foreign_key: :owner_id,
           dependent: :restrict_with_error, inverse_of: :owner
  belongs_to :current_workspace, class_name: "Workspace", optional: true

  encrypts :otp_secret

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { maximum: 120 }
  validates :password, password_strength: true, allow_nil: true

  generates_token_for :email_confirmation, expires_in: 24.hours do
    email_address
  end

  scope :confirmed,   -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :locked,      -> { where.not(locked_at: nil).where("locked_at > ?", LOCK_DURATION.ago) }

  def confirmed?    = confirmed_at.present?
  def locked?       = locked_at.present? && locked_at > LOCK_DURATION.ago
  def otp_enabled?  = otp_enabled_at.present?

  def dashboard_section_enabled?(section)
    dashboard_section_states.fetch(section.to_s, true)
  end

  def reload(*)
    @dashboard_section_states = nil
    super
  end

  private

  def dashboard_section_states
    @dashboard_section_states ||= dashboard_preferences.pluck(:section, :enabled).to_h
  end
end
