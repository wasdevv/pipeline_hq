# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthEventJob, type: :job do
  let(:user)   { create(:user) }
  let(:params) do
    {
      kind:          "login_success",
      user_id:       user.id,
      email_address: user.email_address,
      ip_address:    "127.0.0.1",
      user_agent:    "RSpec/TestAgent",
      metadata:      { reason: "test" }
    }
  end

  it "is queued on :low" do
    expect(described_class.new.queue_name).to eq("low")
  end

  it "creates an AuthEvent with the given attributes" do
    expect { described_class.perform_now(**params) }
      .to change(AuthEvent, :count).by(1)

    event = AuthEvent.last
    expect(event.kind).to eq("login_success")
    expect(event.user_id).to eq(user.id)
    expect(event.email_address).to eq(user.email_address)
    expect(event.ip_address).to eq("127.0.0.1")
    expect(event.user_agent).to eq("RSpec/TestAgent")
    expect(event.metadata).to eq({ "reason" => "test" })
  end

  it "logs and swallows RecordInvalid (e.g., invalid kind)" do
    bad = params.merge(kind: "not_a_real_kind")

    expect(Rails.logger).to receive(:warn).with(/AuthEventJob skipped/)
    expect { described_class.perform_now(**bad) }.not_to change(AuthEvent, :count)
  end

  it "discards on DeserializationError (declared via discard_on)" do
    expect(described_class.rescue_handlers.flatten).to include("ActiveJob::DeserializationError")
  end
end
