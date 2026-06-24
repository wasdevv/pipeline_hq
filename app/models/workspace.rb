# frozen_string_literal: true

class Workspace < ApplicationRecord
  belongs_to :owner, class_name: "User", inverse_of: :owned_workspaces

  has_many :workspace_memberships, dependent: :destroy, inverse_of: :workspace
  has_many :members, through: :workspace_memberships, source: :user

  has_many :accounts,      dependent: :destroy, inverse_of: :workspace
  has_many :contacts,      dependent: :destroy, inverse_of: :workspace
  has_many :stages,        dependent: :destroy, inverse_of: :workspace
  has_many :deals,         dependent: :destroy, inverse_of: :workspace
  has_many :activities,    dependent: :destroy, inverse_of: :workspace
  has_many :domain_events, dependent: :destroy, inverse_of: :workspace

  validates :name, presence: true, length: { in: 2..80 }
  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9-]+\z/ }, length: { in: 2..80 }
end
