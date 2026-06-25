# frozen_string_literal: true

class WorkspaceMembershipPolicy < ApplicationPolicy
  def index?   = member_of_workspace?
  def show?    = false
  def create?  = false
  def update?  = false
  def destroy? = false

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(workspace_id: Current.workspace&.id)
    end
  end

  private

  def member_of_workspace?
    user&.workspace_memberships&.exists?(workspace_id: Current.workspace&.id)
  end
end
