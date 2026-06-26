# frozen_string_literal: true

class MessagesController < ApplicationController
  include WorkspaceScoped

  def create
    @conversation = policy_scope(Conversation).find(params[:conversation_id])
    authorize Message.new(conversation: @conversation)

    result = Messages::Send.call(
      conversation: @conversation,
      sender: current_user,
      body: params.dig(:message, :body)
    )

    respond_to do |format|
      if result.success?
        @message = result.payload
        format.turbo_stream
        format.html { redirect_to conversation_path(@conversation) }
      else
        format.turbo_stream { head :unprocessable_content }
        format.html { redirect_to conversation_path(@conversation), alert: t("messages.errors.#{result.code}") }
      end
    end
  end
end
