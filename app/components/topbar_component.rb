# frozen_string_literal: true

class TopbarComponent < ViewComponent::Base
  def initialize(current_user:, current_workspace:)
    @current_user = current_user
    @current_workspace = current_workspace
  end

  def user_initials
    parts = @current_user.name.to_s.split.first(2)
    parts.map { |p| p[0] }.join.upcase
  end

  def first_name
    @current_user.name.to_s.split.first
  end
end
