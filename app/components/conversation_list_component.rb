# frozen_string_literal: true

class ConversationListComponent < ViewComponent::Base
  AVATAR_COLORS = [
    { bg: "bg-indigo-100 dark:bg-indigo-900", text: "text-indigo-700 dark:text-indigo-300" },
    { bg: "bg-violet-100 dark:bg-violet-900", text: "text-violet-700 dark:text-violet-300" },
    { bg: "bg-sky-100 dark:bg-sky-900",       text: "text-sky-700 dark:text-sky-300" },
    { bg: "bg-emerald-100 dark:bg-emerald-900", text: "text-emerald-700 dark:text-emerald-300" },
    { bg: "bg-amber-100 dark:bg-amber-900",   text: "text-amber-700 dark:text-amber-300" },
    { bg: "bg-rose-100 dark:bg-rose-900",     text: "text-rose-700 dark:text-rose-300" }
  ].freeze

  def initialize(conversations:, current_user:, active_id: nil)
    @conversations = conversations
    @current_user = current_user
    @active_id = active_id
  end

  def display_name(conversation)
    other = conversation.other_member_for(@current_user)
    other&.name.presence || "Conversa"
  end

  def initials(name)
    name.to_s.split.first(2).map { |p| p[0] }.join.upcase
  end

  def avatar_color(name)
    AVATAR_COLORS[name.to_s.sum % AVATAR_COLORS.length]
  end

  def last_message_text(conversation)
    conversation.messages.last&.body.to_s.truncate(60).presence || "Diga oi!"
  end

  def relative_time(conversation)
    timestamp = conversation.last_message_at || conversation.created_at
    return "" if timestamp.blank?

    if timestamp.today?
      I18n.l(timestamp, format: :short)
    elsif timestamp > 7.days.ago
      "há #{((Time.current - timestamp) / 1.day).to_i}d"
    else
      I18n.l(timestamp.to_date)
    end
  end

  def unread_count_for(conversation)
    conversation.participant_for(@current_user)&.unread_count.to_i
  end
end
