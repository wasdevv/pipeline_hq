# frozen_string_literal: true

require "vcr"

ENV["ANTHROPIC_API_KEY"] = "sk-ant-test"

VCR.configure { |config| config.ignore_hosts "api.anthropic.com" }

module AnthropicHelpers
  MESSAGES_URL = "https://api.anthropic.com/v1/messages"

  def anthropic_message(content, stop_reason:, input_tokens: 100, output_tokens: 20)
    {
      id: "msg_#{SecureRandom.hex(6)}", type: "message", role: "assistant", model: Chat::Reply::DEFAULT_MODEL,
      content: content, stop_reason: stop_reason, stop_sequence: nil,
      usage: { input_tokens: input_tokens, output_tokens: output_tokens }
    }
  end

  def anthropic_text(text, **usage)
    anthropic_message([ { type: "text", text: text } ], stop_reason: "end_turn", **usage)
  end

  def anthropic_tool_use(name, input, id: "toolu_#{SecureRandom.hex(6)}", **usage)
    anthropic_message([ { type: "tool_use", id: id, name: name, input: input } ], stop_reason: "tool_use", **usage)
  end

  def anthropic_ok(body)
    { status: 200, body: body.to_json, headers: { "content-type" => "application/json" } }
  end

  def anthropic_error(status, type)
    { status: status, body: { type: "error", error: { type: type, message: "stubbed #{status}" } }.to_json,
      headers: { "content-type" => "application/json" } }
  end

  def stub_anthropic(*responses)
    @anthropic_bodies = []
    queue = responses.dup
    stub_request(:post, MESSAGES_URL).to_return do |request|
      @anthropic_bodies << JSON.parse(request.body)
      queue.size > 1 ? queue.shift : queue.first
    end
  end

  def anthropic_bodies
    @anthropic_bodies || []
  end
end

RSpec.configure { |config| config.include AnthropicHelpers }
