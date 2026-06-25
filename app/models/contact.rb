# frozen_string_literal: true

class Contact < ApplicationRecord
  belongs_to :workspace, inverse_of: :contacts
  belongs_to :account, inverse_of: :contacts

  has_many :deals, dependent: :nullify, inverse_of: :contact
end
