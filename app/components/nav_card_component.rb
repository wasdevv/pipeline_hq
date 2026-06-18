# frozen_string_literal: true

class NavCardComponent < ViewComponent::Base
  def initialize(title:, subtitle:, href:)
    @title = title
    @subtitle = subtitle
    @href = href
  end
end
