# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatMessage, type: :model do
  let(:session) { create(:chat_session) }

  it { is_expected.to belong_to(:chat_session) }
  it { is_expected.to define_enum_for(:role).with_values(user: 0, assistant: 1, tool: 2).validating }

  it "inherits the workspace from its session" do
    message = create(:chat_message, chat_session: session)

    expect(message.workspace_id).to eq(session.workspace_id)
  end

  it "refuses a workspace different from the session's" do
    message = build(:chat_message, chat_session: session, workspace: create(:workspace))

    expect(message).not_to be_valid
    expect(message.errors[:workspace]).to be_present
  end

  it "rejects negative token counts at the database too" do
    message = create(:chat_message, chat_session: session)

    expect { message.update_columns(tokens_in: -1) }.to raise_error(ActiveRecord::StatementInvalid, /chat_messages_tokens_check/)
  end

  it "extracts only text blocks" do
    message = build(:chat_message, content: [
      { "type" => "text", "text" => "Vou buscar." },
      { "type" => "tool_use", "id" => "toolu_1", "name" => "list_deals", "input" => {} },
      { "type" => "text", "text" => "Pronto." }
    ])

    expect(message.text).to eq("Vou buscar.\n\nPronto.")
  end
end
