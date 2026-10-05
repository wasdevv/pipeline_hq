# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CRM chatbot", type: :system do
  include ActiveJob::TestHelper

  let(:user)      { create(:user) }
  let(:workspace) { user.current_workspace }

  before do
    perform_enqueued_jobs do
      page.driver.post session_path, { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  it "asks a question, the job answers with CRM data, and the answer shows up in the session history" do
    account = create(:account, workspace: workspace, name: "Acme Tecnologia")
    stub_anthropic(
      anthropic_ok(anthropic_tool_use("search_accounts", { query: "acme" })),
      anthropic_ok(anthropic_text("Encontrei a conta Acme Tecnologia."))
    )

    visit root_path
    expect(page).to have_css("button[popovertarget='chat-panel']")
    expect(page).to have_css("aside#chat-panel[popover] turbo-frame#chat_panel[src='#{chat_sessions_path}']", visible: :all)

    visit chat_sessions_path
    click_button I18n.t("chat.panel.new_session")
    fill_in I18n.t("chat.panel.input_label"), with: "Temos a Acme na base?"
    perform_enqueued_jobs { click_button I18n.t("chat.panel.send") }

    visit chat_sessions_path
    expect(page).to have_text("Temos a Acme na base?")
    expect(page).to have_text("Encontrei a conta Acme Tecnologia.")
    expect(JSON.parse(anthropic_bodies.last["messages"].last["content"].first["content"])["accounts"].first["id"]).to eq(account.id)
    expect(DomainEvent.where(kind: "chat.message_sent", workspace: workspace).count).to eq(1)
  end
end
