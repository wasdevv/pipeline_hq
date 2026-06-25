# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Workspace flow", type: :system do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  before do
    driven_by :rack_test
    perform_enqueued_jobs do
      page.driver.post session_path, { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  it "user starts with a default workspace from signup" do
    visit root_path
    expect(user.current_workspace).to be_present
    expect(page).to have_content(user.current_workspace.name)
  end

  it "user creates a second workspace and switches to it" do
    expect {
      visit new_workspace_path
      fill_in "Nome", with: "Acme Corp"
      click_button "Criar"
    }.to change(user.reload.workspaces, :count).by(1)

    expect(user.reload.current_workspace.name).to eq("Acme Corp")
  end
end
