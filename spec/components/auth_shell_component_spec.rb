# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthShellComponent, type: :component do
  it "renders the title" do
    render_inline(described_class.new(title: "Sign in")) { "form contents" }
    expect(page).to have_content("Sign in")
    expect(page).to have_content("form contents")
  end

  it "renders the subtitle when present" do
    render_inline(described_class.new(title: "Sign in", subtitle: "Welcome back")) { "x" }
    expect(page).to have_content("Welcome back")
  end

  it "renders the footer when present" do
    render_inline(described_class.new(title: "Sign in", footer: "Need help?")) { "x" }
    expect(page).to have_content("Need help?")
  end

  it "omits the subtitle and footer when nil" do
    render_inline(described_class.new(title: "Sign in")) { "x" }
    expect(page).to have_content("Sign in")
  end
end
