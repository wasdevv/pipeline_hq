# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :workspace, inverse_of: :accounts

  has_many :contacts,      dependent: :destroy, inverse_of: :account
  has_many :deals,         dependent: :destroy, inverse_of: :account
  has_many :domain_events, as: :subject, dependent: :nullify
end
