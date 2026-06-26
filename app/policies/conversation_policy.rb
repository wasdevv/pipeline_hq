# frozen_string_literal: true

class ConversationPolicy < ApplicationPolicy
  def index?  = membership.present?
  def show?   = participant?
  def new?    = membership.present?
  def create? = membership.present?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(workspace_id: Current.workspace&.id).for_user(user)
    end
  end

  private

  def participant?
    scoped_to_workspace? && record.participants.exists?(user_id: user.id)
  end
end
