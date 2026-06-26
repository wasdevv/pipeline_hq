# frozen_string_literal: true

require "rails_helper"

RSpec.describe DomainEventJob, type: :job do
  let(:workspace) { create(:workspace, owner: create(:user)) }
  let(:actor)     { create(:user) }

  let(:valid_params) do
    {
      kind:         "account.created",
      workspace_id: workspace.id,
      actor_id:     actor.id,
      subject_type: nil,
      subject_id:   nil,
      metadata:     { "source" => "spec" }
    }
  end

  it "is queued on :low" do
    expect(described_class.new.queue_name).to eq("low")
  end

  it "creates a DomainEvent with the given attributes" do
    expect { described_class.perform_now(**valid_params) }
      .to change(DomainEvent, :count).by(1)

    event = DomainEvent.last
    expect(event.kind).to eq("account.created")
    expect(event.workspace_id).to eq(workspace.id)
    expect(event.actor_id).to eq(actor.id)
    expect(event.subject_type).to be_nil
    expect(event.subject_id).to be_nil
    expect(event.metadata).to eq({ "source" => "spec" })
  end

  it "logs and swallows RecordInvalid (e.g., invalid kind)" do
    bad = valid_params.merge(kind: "not.a.valid.kind")

    expect(Rails.logger).to receive(:warn).with(/DomainEventJob skipped/)
    expect { described_class.perform_now(**bad) }.not_to change(DomainEvent, :count)
  end

  it "logs and swallows ConnectionTimeoutError" do
    allow(DomainEvent).to receive(:create!).and_raise(ActiveRecord::ConnectionTimeoutError, "connection timeout")

    expect(Rails.logger).to receive(:warn).with(/DomainEventJob connection timeout/)
    expect { described_class.perform_now(**valid_params) }.not_to raise_error
  end

  it "discards on DeserializationError (declared via discard_on)" do
    expect(described_class.rescue_handlers.flatten).to include("ActiveJob::DeserializationError")
  end
end
