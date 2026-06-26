# frozen_string_literal: true

class ConversationThreadComponent < ViewComponent::Base
  def initialize(conversation:, current_user:, messages: nil)
    @conversation = conversation
    @current_user = current_user
    @messages = messages || conversation.messages.includes(:sender).chronological
  end

  def other_member
    @other_member ||= @conversation.other_member_for(@current_user)
  end

  def display_name
    other_member&.name.presence || "Conversa"
  end

  def initials(name)
    name.to_s.split.first(2).map { |p| p[0] }.join.upcase
  end

  def initial_online?
    other_member && Presence::Tracker.online?(@conversation.workspace_id, other_member.id)
  end

  def grouped_messages
    @messages.group_by { |m| day_label(m.created_at) }
  end

  def day_label(timestamp)
    if timestamp.today?           then "Hoje"
    elsif timestamp.yesterday?    then "Ontem"
    else                               I18n.l(timestamp.to_date, format: :long)
    end
  end

  def stream_name
    [ @conversation, :messages, @current_user.id ]
  end
end
