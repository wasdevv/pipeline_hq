# frozen_string_literal: true

module WorkspaceScoped
  extend ActiveSupport::Concern

  included do
    before_action :require_workspace
    helper_method :current_workspace
  end

  private

  def current_workspace
    Current.workspace
  end

  def require_workspace
    redirect_to new_workspace_path, alert: t("workspaces.no_workspace") unless current_workspace
  end
end
