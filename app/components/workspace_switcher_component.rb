# frozen_string_literal: true

class WorkspaceSwitcherComponent < ViewComponent::Base
  def initialize(current_user:, current_workspace:)
    @current_user = current_user
    @current_workspace = current_workspace
  end

  def workspaces
    @workspaces ||= @current_user.workspaces.order(:name)
  end

  def active?(workspace)
    @current_workspace&.id == workspace.id
  end
end
