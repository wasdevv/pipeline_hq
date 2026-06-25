# frozen_string_literal: true

class WorkspaceMembershipsController < ApplicationController
  include WorkspaceScoped

  def index
    authorize current_workspace, :show?, policy_class: WorkspacePolicy
    @memberships = WorkspaceMembership
                     .where(workspace: current_workspace)
                     .includes(:user)
                     .order(created_at: :asc)
  end
end
