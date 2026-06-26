# frozen_string_literal: true

class DomainEvent < ApplicationRecord
  KINDS = %w[
    workspace.created workspace.updated workspace.switched
    membership.added membership.role_changed membership.removed
    account.created account.updated account.destroyed
    contact.created contact.updated contact.destroyed
    stage.created stage.updated stage.destroyed
    deal.created deal.updated deal.destroyed
    activity.created activity.updated activity.destroyed
  ].freeze

  self.inheritance_column = nil

  belongs_to :workspace, inverse_of: :domain_events
  belongs_to :actor, class_name: "User", optional: true, inverse_of: :domain_events
  belongs_to :subject, polymorphic: true, optional: true

  validates :kind, presence: true, inclusion: { in: KINDS }

  scope :recent, -> { order(created_at: :desc) }
end
