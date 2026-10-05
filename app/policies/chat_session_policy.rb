# frozen_string_literal: true

class ChatSessionPolicy < ApplicationPolicy
  def index?   = membership.present?
  def create?  = membership.present?
  def show?    = owned? && membership.present?
  def ask?     = show?
  def update?  = false
  def destroy? = false

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(workspace_id: Current.workspace&.id).for_user(user)
    end
  end

  private

  def owned?
    scoped_to_workspace? && record.user_id == user&.id
  end
end
