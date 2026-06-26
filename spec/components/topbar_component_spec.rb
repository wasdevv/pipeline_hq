# frozen_string_literal: true

require "rails_helper"

RSpec.describe TopbarComponent, type: :component do
  let(:user)      { create(:user, name: "Maria Souza") }
  let(:workspace) { user.current_workspace }

  it "renders the PipelineHQ brand link to root" do
    render_inline(described_class.new(current_user: user, current_workspace: workspace))
    expect(page).to have_link("PipelineHQ", href: "/", visible: :all)
  end

  it "embeds the workspace switcher" do
    render_inline(described_class.new(current_user: user, current_workspace: workspace))
    expect(page).to have_content(workspace.name)
  end

  it "shows the user's first name" do
    render_inline(described_class.new(current_user: user, current_workspace: workspace))
    expect(page).to have_content("Maria", normalize_ws: true)
  end

  it "shows the user's initials in the avatar" do
    render_inline(described_class.new(current_user: user, current_workspace: workspace))
    expect(page).to have_content("MS")
  end

  it "renders the theme toggle button" do
    render_inline(described_class.new(current_user: user, current_workspace: workspace))
    expect(page).to have_css("[data-controller='theme']")
  end

  it "renders account menu links in the dropdown" do
    render_inline(described_class.new(current_user: user, current_workspace: workspace))

    expect(page).to have_link("Sessões ativas", href: "/sessions_management", visible: :all)
    expect(page).to have_link("Autenticação 2FA", href: "/two_factor", visible: :all)
    expect(page).to have_link("Auditoria do workspace", href: "/domain_events", visible: :all)
  end

  it "renders a sign-out button" do
    render_inline(described_class.new(current_user: user, current_workspace: workspace))
    expect(page).to have_button("Sair", visible: :all)
  end

  it "shows the user's email in the dropdown header" do
    render_inline(described_class.new(current_user: user, current_workspace: workspace))
    expect(page).to have_content(user.email_address)
  end

  describe "#user_initials" do
    it "returns the first 2 initials" do
      component = described_class.new(current_user: user, current_workspace: workspace)
      expect(component.user_initials).to eq("MS")
    end

    it "handles single-word names" do
      single = build(:user, name: "Wash")
      component = described_class.new(current_user: single, current_workspace: workspace)
      expect(component.user_initials).to eq("W")
    end
  end

  describe "#first_name" do
    it "returns the first whitespace-separated part of the name" do
      component = described_class.new(current_user: user, current_workspace: workspace)
      expect(component.first_name).to eq("Maria")
    end
  end
end
