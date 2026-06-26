# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes

  helper_method :current_workspace, :unread_messages_count

  rescue_from Pundit::NotAuthorizedError, with: :pundit_not_authorized

  private

  def current_workspace
    Current.workspace
  end

  def unread_messages_count
    return 0 unless current_user && current_workspace

    @unread_messages_count ||= Message
      .joins(conversation: :participants)
      .where(conversations: { workspace_id: current_workspace.id })
      .where(conversation_participants: { user_id: current_user.id })
      .where.not(sender_id: current_user.id)
      .where("messages.created_at > COALESCE(conversation_participants.last_read_at, '1970-01-01')")
      .count
  end

  def pundit_not_authorized
    flash[:alert] = t("pundit.not_authorized")
    redirect_back_or_to root_path, status: :see_other
  end
end
