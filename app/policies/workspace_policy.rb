# frozen_string_literal: true

class WorkspacePolicy < ApplicationPolicy
  def index?   = true
  def show?    = member_of_record?
  def new?     = create?
  def create?  = user.present?
  def edit?    = update?
  def update?  = member_of_record? && elevated_in_record?
  def destroy? = false

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      user.workspaces
    end
  end

  private

  def member_of_record?
    @member_of_record ||= user&.workspace_memberships&.exists?(workspace_id: record.id)
  end

  def elevated_in_record?
    mem = user&.workspace_memberships&.find_by(workspace_id: record.id)
    mem&.owner? || mem&.admin?
  end
end
