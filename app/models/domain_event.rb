# frozen_string_literal: true

class DomainEvent < ApplicationRecord
  belongs_to :workspace, inverse_of: :domain_events
  belongs_to :actor, class_name: "User", optional: true, inverse_of: :domain_events
  belongs_to :subject, polymorphic: true, optional: true

  validates :kind, presence: true, length: { maximum: 64 }
end
