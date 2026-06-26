# frozen_string_literal: true

class ConversationsController < ApplicationController
  include WorkspaceScoped

  before_action :set_conversation, only: :show

  def index
    @conversations = scoped_conversations
    @active_conversation = nil
  end

  def show
    authorize @conversation
    Conversations::MarkRead.call(participant: @conversation.participant_for(current_user))
    @conversations = scoped_conversations
    @messages = @conversation.messages.includes(:sender).chronological
  end

  def new
    authorize Conversation.new(workspace: current_workspace), :new?
    @candidates = current_workspace.members
                                   .where.not(id: current_user.id)
                                   .order(:name)
  end

  def create
    recipient = current_workspace.members.find_by(id: params[:recipient_id])
    return redirect_to new_conversation_path, alert: t("conversations.recipient_required") unless recipient

    result = Conversations::FindOrCreateDirect.call(
      workspace: current_workspace,
      initiator: current_user,
      recipient: recipient
    )

    if result.success?
      redirect_to conversation_path(result.payload)
    else
      redirect_to new_conversation_path, alert: t("conversations.errors.#{result.code}")
    end
  end

  private

  def scoped_conversations
    policy_scope(Conversation).ordered_by_recent.includes(participants: :user, messages: :sender)
  end

  def set_conversation
    @conversation = policy_scope(Conversation).find(params[:id])
  end
end
