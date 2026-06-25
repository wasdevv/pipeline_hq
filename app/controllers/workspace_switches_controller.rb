# frozen_string_literal: true

class WorkspaceSwitchesController < ApplicationController
  def create
    workspace = Workspace.find_by(id: params[:id])
    result = Workspaces::Switch.call(user: current_user, workspace: workspace)

    if result.success?
      session[:current_workspace_id] = result.payload.id
      Current.workspace = result.payload
      redirect_to request.referer || root_path, notice: t("workspaces.switched")
    else
      redirect_to root_path, alert: t("pundit.not_authorized")
    end
  end
end
