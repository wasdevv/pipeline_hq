# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthHeaderComponent, type: :component do
  it "renders the title" do
    render_inline(described_class.new(title: "Welcome"))
    expect(page).to have_content("Welcome")
  end

  it "renders the subtitle when present" do
    render_inline(described_class.new(title: "Welcome", subtitle: "Sign in to continue"))
    expect(page).to have_content("Sign in to continue")
  end
end
