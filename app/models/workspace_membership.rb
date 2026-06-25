# frozen_string_literal: true

class WorkspaceMembership < ApplicationRecord
  belongs_to :workspace, inverse_of: :workspace_memberships
  belongs_to :user, inverse_of: :workspace_memberships

  enum :role, { owner: 0, admin: 1, member: 2, viewer: 3 }, default: :member

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :workspace_id }
end
