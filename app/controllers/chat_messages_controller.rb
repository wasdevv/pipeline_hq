# frozen_string_literal: true

class ChatMessagesController < ApplicationController
  include WorkspaceScoped

  RATE_LIMIT = 10
  RATE_WINDOW = 1.minute

  rate_limit to: RATE_LIMIT, within: RATE_WINDOW, only: :create,
             by: -> { current_user.id },
             with: -> { render_error(:throttled, :too_many_requests) }

  def create
    @chat_session = policy_scope(ChatSession).find(params[:chat_session_id])
    authorize @chat_session, :ask?

    result = Chat::Ask.call(session: @chat_session, user: current_user, text: params.dig(:chat_message, :text))
    return render_error(result.code, result.code == :busy ? :conflict : :unprocessable_content) if result.failure?

    @message = result.payload
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to root_path }
    end
  end

  private

  def render_error(code, status)
    @error = t("chat.errors.#{code}")
    respond_to do |format|
      format.turbo_stream { render :error, status: status }
      format.html { redirect_back_or_to root_path, alert: @error }
    end
  end
end
