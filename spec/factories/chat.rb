# frozen_string_literal: true

FactoryBot.define do
  factory :chat_session do
    association :user
    workspace { user.current_workspace }
  end

  factory :chat_message do
    association :chat_session
    role { :user }
    content { ChatMessage.text_block("Quais negócios fecham este mês?") }
  end
end
