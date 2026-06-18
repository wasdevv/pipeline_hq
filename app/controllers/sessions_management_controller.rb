# frozen_string_literal: true

class SessionsManagementController < ApplicationController
  def index
    @sessions = current_user.sessions.by_recency
  end

  def destroy
    target = current_user.sessions.find(params[:id])
    target.destroy!
    AuthEvents::Record.call(kind: :session_revoked, user: current_user, request: request)
    redirect_to sessions_management_index_path, notice: "Sessão revogada."
  end

  def destroy_all
    current_user.sessions.except_current(current_session).destroy_all
    AuthEvents::Record.call(kind: :sessions_revoked_all, user: current_user, request: request)
    redirect_to sessions_management_index_path, notice: "Outras sessões revogadas."
  end
end
