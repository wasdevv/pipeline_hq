# frozen_string_literal: true

class AuthShellComponent < ViewComponent::Base
  def initialize(title:, subtitle: nil, footer: nil)
    @title = title
    @subtitle = subtitle
    @footer = footer
  end
end
