# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::Lock do
  include ActiveJob::TestHelper
  include_context "with a request double"

  describe ".call" do
    let(:user) { create(:user, failed_attempts: 5) }

    it "stamps locked_at on the user" do
      expect {
        perform_enqueued_jobs { described_class.call(user: user, request: request) }
      }.to change { user.reload.locked_at }.from(nil)
    end

    it "records an account_locked AuthEvent with failed_attempts in metadata" do
      expect {
        perform_enqueued_jobs { described_class.call(user: user, request: request) }
      }.to change { AuthEvent.where(kind: "account_locked", user: user).count }.by(1)

      event = AuthEvent.where(kind: "account_locked", user: user).last
      expect(event.metadata["failed_attempts"]).to eq(5)
      expect(event.ip_address).to eq("127.0.0.1")
    end

    it "marks the user as locked? per the model predicate" do
      perform_enqueued_jobs { described_class.call(user: user, request: request) }
      expect(user.reload).to be_locked
    end
  end
end
