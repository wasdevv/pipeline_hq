# frozen_string_literal: true

class PageHeaderComponent < ViewComponent::Base
  def initialize(title:, subtitle: nil, action_label: nil, action_path: nil)
    @title = title
    @subtitle = subtitle
    @action_label = action_label
    @action_path = action_path
  end
end
