# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatPanelComponent, type: :component do
  let(:session) { create(:chat_session) }

  it "renders user and assistant messages, escaping their HTML" do
    create(:chat_message, chat_session: session, content: ChatMessage.text_block("<script>alert(1)</script>"))
    create(:chat_message, chat_session: session, role: :assistant, content: ChatMessage.text_block("Resposta"))

    render_inline(described_class.new(chat_session: session))

    expect(page).to have_css("li", text: "<script>alert(1)</script>")
    expect(page).not_to have_css("script", visible: :all)
    expect(page).to have_text("Resposta")
  end

  it "hides tool payloads and assistant turns without text" do
    create(:chat_message, chat_session: session, role: :tool,
                          content: [ { "type" => "tool_result", "tool_use_id" => "t", "content" => "dado interno" } ])
    create(:chat_message, chat_session: session, role: :assistant,
                          content: [ { "type" => "tool_use", "id" => "t", "name" => "list_deals", "input" => {} } ])

    render_inline(described_class.new(chat_session: session))

    expect(page).not_to have_text("dado interno")
    expect(page).not_to have_css("li")
  end

  it "shows the thinking indicator only while a reply is in progress" do
    render_inline(described_class.new(chat_session: session))
    expect(page).not_to have_text(I18n.t("chat.panel.thinking"))

    session.reserve_reply!
    render_inline(described_class.new(chat_session: session.reload))
    expect(page).to have_css("##{ActionView::RecordIdentifier.dom_id(session, :thinking)}", text: I18n.t("chat.panel.thinking"))
  end

  it "wires the Stimulus controller for Enter-to-send" do
    render_inline(described_class.new(chat_session: session))

    expect(page).to have_css("form[data-controller='chat'] textarea[data-chat-target='input']")
  end

  it "offers a new conversation when there is no session" do
    render_inline(described_class.new(chat_session: nil))

    expect(page).to have_button(I18n.t("chat.panel.new_session"))
    expect(page).not_to have_css("textarea")
  end
end
