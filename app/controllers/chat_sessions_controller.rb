# frozen_string_literal: true

class ChatSessionsController < ApplicationController
  include WorkspaceScoped

  def index
    authorize ChatSession
    @chat_session = policy_scope(ChatSession).recent_first.first
    render :show
  end

  def show
    @chat_session = policy_scope(ChatSession).find(params[:id])
    authorize @chat_session
  end

  def create
    authorize ChatSession
    chat_session = current_workspace.chat_sessions.create!(user: current_user)
    redirect_to chat_session_path(chat_session)
  end
end
