# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?   = membership.present?
  def show?    = scoped_to_workspace? && membership.present?
  def new?     = create?
  def create?  = membership&.member? || elevated?
  def edit?    = update?
  def update?  = scoped_to_workspace? && (membership&.member? || elevated?)
  def destroy? = scoped_to_workspace? && elevated?

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

  def membership
    @membership ||= user&.workspace_memberships&.find_by(workspace_id: Current.workspace&.id)
  end

  def elevated?
    membership&.owner? || membership&.admin?
  end

  def scoped_to_workspace?
    record.workspace_id == Current.workspace&.id
  end
end
