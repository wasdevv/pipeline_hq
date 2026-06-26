# frozen_string_literal: true

class MessageBubbleComponent < ViewComponent::Base
  def initialize(message:, viewer_id:)
    @message = message
    @viewer_id = viewer_id
  end

  def sent?
    @message.sender_id == @viewer_id
  end

  def sender_name
    @message.sender&.name.presence || "Desconhecido"
  end

  def sender_initials
    sender_name.split.first(2).map { |p| p[0] }.join.upcase
  end

  def time_label
    I18n.l(@message.created_at, format: :short)
  end
end
