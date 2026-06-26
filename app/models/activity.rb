# frozen_string_literal: true

class Activity < ApplicationRecord
  belongs_to :workspace, inverse_of: :activities
  belongs_to :deal, inverse_of: :activities

  has_many :domain_events, as: :subject, dependent: :nullify
end
