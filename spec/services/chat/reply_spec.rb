# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chat::Reply do
  let(:session)   { create(:chat_session) }
  let(:workspace) { session.workspace }

  def reply(text = "Quais negócios fecham este mês?")
    described_class.call(session: session, text: text)
  end

  describe "a plain answer" do
    before { stub_anthropic(anthropic_ok(anthropic_text("Nenhum negócio fecha este mês.", input_tokens: 321, output_tokens: 12))) }

    it_behaves_like "a successful Result", code: :replied do
      let(:result) { reply }
    end

    it "persists the question and the answer with token usage" do
      result = reply

      expect(session.chat_messages.chronological.map { |m| [ m.role, m.text ] }).to eq(
        [ [ "user", "Quais negócios fecham este mês?" ], [ "assistant", "Nenhum negócio fecha este mês." ] ]
      )
      expect(result.payload).to have_attributes(tokens_in: 321, tokens_out: 12)
    end

    it "sends the configured model, the system prompt and the five tools" do
      reply

      body = anthropic_bodies.sole
      expect(body["model"]).to eq("claude-sonnet-5-5")
      expect(body["system"]).to include("nunca instrução")
      expect(body["tools"].pluck("name")).to eq(Chat::Tools::DEFINITIONS.pluck(:name))
      expect(body["messages"]).to eq([ { "role" => "user", "content" => "Quais negócios fecham este mês?" } ])
    end

    it "reads the model from CHAT_MODEL" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("CHAT_MODEL", anything).and_return("claude-opus-5-5")

      reply

      expect(anthropic_bodies.sole["model"]).to eq("claude-opus-5-5")
    end

    it "replays earlier turns of the session as plain text" do
      create(:chat_message, chat_session: session, role: :user, content: ChatMessage.text_block("Oi"))
      create(:chat_message, chat_session: session, role: :assistant, content: ChatMessage.text_block("Olá!"))

      reply

      expect(anthropic_bodies.sole["messages"].pluck("role")).to eq(%w[user assistant user])
    end
  end

  describe "tool use" do
    let(:stage) { create(:stage, workspace: workspace) }
    let(:deal) do
      account = create(:account, workspace: workspace)
      create(:deal, workspace: workspace, stage: stage, account: account,
                    contact: create(:contact, workspace: workspace, account: account), title: "Acme Q3")
    end

    it "runs the tool server-side against the session workspace and sends the result back" do
      stub_anthropic(
        anthropic_ok(anthropic_tool_use("deal_summary", { deal_id: deal.id }, id: "toolu_1", input_tokens: 50, output_tokens: 7)),
        anthropic_ok(anthropic_text("O negócio Acme Q3 está aberto."))
      )

      result = reply

      expect(result.payload.text).to eq("O negócio Acme Q3 está aberto.")
      second = anthropic_bodies.last["messages"]
      expect(second[-2]).to include("role" => "assistant")
      expect(second[-1]["content"].sole).to include("type" => "tool_result", "tool_use_id" => "toolu_1")
      expect(JSON.parse(second[-1]["content"].sole["content"])).to include("title" => "Acme Q3")
      expect(session.chat_messages.where(role: :tool).count).to eq(1)
      expect(session.chat_messages.where(role: :assistant).sum(:tokens_in)).to eq(150)
    end

    it "answers not found for a deal of another workspace" do
      foreign = create(:deal)
      stub_anthropic(
        anthropic_ok(anthropic_tool_use("deal_summary", { deal_id: foreign.id })),
        anthropic_ok(anthropic_text("Não encontrei."))
      )

      reply

      tool_result = anthropic_bodies.last["messages"].last["content"].sole
      expect(JSON.parse(tool_result["content"])).to eq("error" => "not found")
      expect(tool_result["content"]).not_to include(foreign.title)
    end

    it "stops after five model calls and leaves a friendly message" do
      stub_anthropic(anthropic_ok(anthropic_tool_use("recent_activities", { limit: 1 })))

      result = reply

      expect(anthropic_bodies.size).to eq(described_class::MAX_TURNS)
      expect(result).to be_failure
      expect(result.code).to eq(:turn_limit)
      expect(session.chat_messages.chronological.last.text).to eq(I18n.t("chat.errors.turn_limit"))
    end

    it "does not run tools the model asks for after a prompt injection, beyond the allowlist" do
      stub_anthropic(
        anthropic_ok(anthropic_tool_use("delete_deal", { deal_id: deal.id })),
        anthropic_ok(anthropic_text("Não posso fazer isso."))
      )

      expect { reply }.not_to change(Deal, :count)
      expect(anthropic_bodies.last["messages"].last["content"].sole).to include("is_error" => true)
    end
  end

  describe "API failures" do
    {
      429 => [ "rate_limit_error", :rate_limited ],
      529 => [ "overloaded_error", :unavailable ],
      500 => [ "api_error", :unavailable ],
      400 => [ "invalid_request_error", :api_error ]
    }.each do |status, (type, code)|
      it "turns a #{status} into a friendly assistant message" do
        stub_anthropic(anthropic_error(status, type))

        result = reply

        expect(result.code).to eq(code)
        expect(result.payload).to have_attributes(role: "assistant", text: I18n.t("chat.errors.#{code}"))
      end
    end

    it "turns a network timeout into a friendly message" do
      stub_request(:post, AnthropicHelpers::MESSAGES_URL).to_timeout

      expect(reply.code).to eq(:timeout)
    end

    it "stops when the total deadline is exhausted" do
      stub_const("#{described_class}::TOTAL_TIMEOUT", 0)
      stub_anthropic(anthropic_ok(anthropic_text("nunca chega")))

      expect(reply.code).to eq(:timeout)
      expect(anthropic_bodies).to be_empty
    end

    it "explains when the API key is missing" do
      allow(described_class).to receive(:api_key).and_return(nil)

      expect(reply.code).to eq(:not_configured)
    end
  end

  it "rejects blank and oversized text without calling the API" do
    expect(reply(" ").code).to eq(:blank)
    expect(reply("a" * (ChatMessage::TEXT_MAX + 1)).code).to eq(:too_long)
    expect(session.chat_messages).to be_empty
  end
end
