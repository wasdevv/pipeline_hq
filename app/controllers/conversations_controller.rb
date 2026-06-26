# frozen_string_literal: true

class ConversationsController < ApplicationController
  include WorkspaceScoped

  PAGE_SIZE = 20

  before_action :set_conversation, only: :show

  def index
    @search_query = params[:q].to_s
    @page = [ params[:page].to_i, 1 ].max
    @conversations = scoped_conversations.search(@search_query).limit(PAGE_SIZE).offset((@page - 1) * PAGE_SIZE)
    @has_more = scoped_conversations.search(@search_query).limit(1).offset(@page * PAGE_SIZE).exists?
    @active_conversation = nil

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    authorize @conversation
    Conversations::MarkRead.call(participant: @conversation.participant_for(current_user))
    @messages = @conversation.messages.includes(:sender).chronological

    return if turbo_frame_request_id == "conversation_thread"

    @search_query = ""
    @page = 1
    @conversations = scoped_conversations.limit(PAGE_SIZE)
    @has_more = scoped_conversations.limit(1).offset(PAGE_SIZE).exists?
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
