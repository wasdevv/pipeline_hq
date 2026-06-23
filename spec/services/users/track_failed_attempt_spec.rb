# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::TrackFailedAttempt do
  include ActiveJob::TestHelper
  include_context "with a request double"

  describe ".call" do
    subject(:call) do
      perform_enqueued_jobs { described_class.call(user: user, request: request) }
    end

    context "below the lock threshold" do
      let(:user) { create(:user, failed_attempts: 0) }

      it "increments failed_attempts by 1" do
        expect { call }.to change { user.reload.failed_attempts }.from(0).to(1)
      end

      it "does not lock the user" do
        expect { call }.not_to change { user.reload.locked_at }
      end

      it "does not record an account_locked AuthEvent" do
        expect { call }.not_to change { AuthEvent.where(kind: "account_locked").count }
      end
    end

    context "when the increment reaches the lock threshold" do
      let(:user) { create(:user, failed_attempts: User::LOCK_THRESHOLD - 1) }

      it "locks the user" do
        expect { call }.to change { user.reload.locked_at }.from(nil)
      end

      it "records an account_locked AuthEvent with the final failed_attempts count" do
        expect { call }.to change { AuthEvent.where(kind: "account_locked", user: user).count }.by(1)

        event = AuthEvent.where(kind: "account_locked", user: user).last
        expect(event.metadata["failed_attempts"]).to eq(User::LOCK_THRESHOLD)
      end
    end

    context "when already past the lock threshold" do
      let(:user) { create(:user, failed_attempts: User::LOCK_THRESHOLD) }

      it "still increments failed_attempts" do
        expect { call }.to change { user.reload.failed_attempts }.by(1)
      end

      it "locks the user again (refreshes locked_at)" do
        expect { call }.to change { AuthEvent.where(kind: "account_locked", user: user).count }.by(1)
      end
    end
  end
end
