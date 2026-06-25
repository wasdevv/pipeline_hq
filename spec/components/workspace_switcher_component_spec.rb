# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkspaceSwitcherComponent, type: :component do
  let(:user)      { create(:user) }
  let(:workspace) { user.current_workspace }

  it "renders the current workspace name" do
    render_inline(described_class.new(current_user: user, current_workspace: workspace))
    expect(page).to have_content(workspace.name)
  end

  it "lists all workspaces the user is a member of" do
    second = Workspaces::Create.call(user: user, name: "Second").payload
    render_inline(described_class.new(current_user: user.reload, current_workspace: second))

    expect(page).to have_content(workspace.name)
    expect(page).to have_content("Second")
  end

  it "includes a link to create a new workspace" do
    render_inline(described_class.new(current_user: user, current_workspace: workspace))
    expect(page).to have_link("Criar workspace", href: "/workspaces/new", visible: :all)
  end
end
