# frozen_string_literal: true

class Deal < ApplicationRecord
  belongs_to :workspace, inverse_of: :deals
  belongs_to :account, inverse_of: :deals
  belongs_to :contact, inverse_of: :deals
  belongs_to :stage, inverse_of: :deals

  has_many :activities, dependent: :destroy, inverse_of: :deal
end
