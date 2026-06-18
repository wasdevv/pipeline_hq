class Deal < ApplicationRecord
  belongs_to :account
  belongs_to :contact
  belongs_to :stage
end
