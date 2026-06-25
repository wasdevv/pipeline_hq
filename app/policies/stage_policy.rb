# frozen_string_literal: true

class StagePolicy < ApplicationPolicy
  def destroy? = scoped_to_workspace? && elevated?

  class Scope < ApplicationPolicy::Scope
  end
end
