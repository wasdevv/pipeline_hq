# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes

  helper_method :current_workspace

  rescue_from Pundit::NotAuthorizedError, with: :pundit_not_authorized

  private

  def current_workspace
    Current.workspace
  end

  def pundit_not_authorized
    flash[:alert] = t("pundit.not_authorized")
    redirect_back_or_to root_path, status: :see_other
  end
end
