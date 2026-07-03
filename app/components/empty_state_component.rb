# frozen_string_literal: true

class EmptyStateComponent < ViewComponent::Base
  def initialize(icon: :inbox, title:, description: nil, action_label: nil, action_path: nil)
    @icon = icon
    @title = title
    @description = description
    @action_label = action_label
    @action_path = action_path
  end

  def icon_path
    case @icon
    when :building
      "M3 21h18M5 21V7l7-4 7 4v14M9 9h1M9 13h1M9 17h1M14 9h1M14 13h1M14 17h1"
    when :users
      "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"
    when :briefcase
      "M3 7h18v13H3zM8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M3 13h18"
    when :columns
      "M3 4h18v16H3zM9 4v16M15 4v16"
    when :activity
      "M22 12h-4l-3 9L9 3l-3 9H2"
    when :chat
      "M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"
    else
      "M3 5h18v14H3zM3 10h18"
    end
  end
end
