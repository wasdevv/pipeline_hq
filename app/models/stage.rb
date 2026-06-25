# frozen_string_literal: true

class Stage < ApplicationRecord
  belongs_to :workspace, inverse_of: :stages

  has_many :deals, dependent: :restrict_with_error, inverse_of: :stage
end
