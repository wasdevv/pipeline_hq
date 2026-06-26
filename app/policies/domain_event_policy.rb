# frozen_string_literal: true

class DomainEventPolicy < ApplicationPolicy
  def index? = membership.present?
  def show?  = false

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(workspace_id: Current.workspace&.id)
    end
  end
end
