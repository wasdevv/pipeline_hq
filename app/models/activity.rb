# frozen_string_literal: true

class Activity < ApplicationRecord
  belongs_to :workspace, inverse_of: :activities
  belongs_to :deal, inverse_of: :activities
end
