# frozen_string_literal: true

class TopbarComponent < ViewComponent::Base
  def initialize(current_user:, current_workspace:, unread_messages_count: 0)
    @current_user = current_user
    @current_workspace = current_workspace
    @unread_messages_count = unread_messages_count
  end

  def user_initials
    parts = @current_user.name.to_s.split.first(2)
    parts.map { |p| p[0] }.join.upcase
  end

  def first_name
    @current_user.name.to_s.split.first
  end

  def unread_badge_visible?
    @unread_messages_count.to_i > 0
  end

  def badge_label
    case @unread_messages_count.to_i
    when 0     then ""
    when 1..99 then @unread_messages_count.to_s
    else            "99+"
    end
  end
end
