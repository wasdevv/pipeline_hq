# frozen_string_literal: true

require "rails_helper"

RSpec.describe PageHeaderComponent, type: :component do
  it "renders the title" do
    render_inline(described_class.new(title: "Empresas"))
    expect(page).to have_css("h1", text: "Empresas")
  end

  it "renders the subtitle when present" do
    render_inline(described_class.new(title: "Empresas", subtitle: "lista de empresas"))
    expect(page).to have_content("lista de empresas")
  end

  it "renders the action link when label and path are provided" do
    render_inline(described_class.new(title: "Empresas", action_label: "Nova empresa", action_path: "/accounts/new"))
    expect(page).to have_link("Nova empresa", href: "/accounts/new")
  end

  it "omits the action link when label is missing" do
    render_inline(described_class.new(title: "Empresas"))
    expect(page).to have_no_link
  end
end
