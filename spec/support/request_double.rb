# frozen_string_literal: true

RequestDouble = Struct.new(:remote_ip, :user_agent, :path, keyword_init: true)

RSpec.shared_context "with a request double" do
  let(:request) do
    RequestDouble.new(
      remote_ip:  "127.0.0.1",
      user_agent: "RSpec/TestAgent",
      path:       "/session"
    )
  end
end
