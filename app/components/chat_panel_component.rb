# frozen_string_literal: true

class ChatPanelComponent < ViewComponent::Base
  HISTORY_SHOWN = 100

  def initialize(chat_session:)
    @chat_session = chat_session
  end

  def messages
    @messages ||= @chat_session.chat_messages.visible.chronological.last(HISTORY_SHOWN).select { |m| m.text.present? }
  end

  def replying?
    @chat_session.replying?
  end
end
