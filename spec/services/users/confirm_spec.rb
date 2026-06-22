# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::Confirm do
  include ActiveJob::TestHelper
  include_context "with a request double"

  describe ".call" do
    subject(:result) do
      perform_enqueued_jobs do
        described_class.call(token: token, request: request)
      end
    end

    context "with a valid token for an unconfirmed user" do
      let(:user)  { create(:user, :unconfirmed) }
      let(:token) { user.generate_token_for(:email_confirmation) }

      it_behaves_like "a successful Result", code: :confirmed

      it "returns the user as payload" do
        expect(result.payload).to eq(user)
      end

      it "stamps confirmed_at on the user" do
        expect { result }.to change { user.reload.confirmed_at }.from(nil)
      end

      it "records an email_confirmed AuthEvent linked to the user" do
        expect { result }.to change { AuthEvent.where(kind: "email_confirmed", user: user).count }.by(1)
      end
    end

    context "with a valid token for an already-confirmed user" do
      let(:user)  { create(:user) }
      let(:token) { user.generate_token_for(:email_confirmation) }

      it_behaves_like "a successful Result", code: :already_confirmed

      it "returns the user as payload" do
        expect(result.payload).to eq(user)
      end

      it "does not move confirmed_at" do
        original = user.confirmed_at
        result
        expect(user.reload.confirmed_at).to be_within(1.second).of(original)
      end

      it "does not record any AuthEvent" do
        expect { result }.not_to change(AuthEvent, :count)
      end
    end

    context "with a malformed token" do
      let(:token) { "not-a-real-token" }

      it_behaves_like "a failed Result", code: :invalid_token

      it "records an email_confirmation_failed AuthEvent with reason metadata" do
        expect { result }.to change { AuthEvent.where(kind: "email_confirmation_failed").count }.by(1)

        event = AuthEvent.where(kind: "email_confirmation_failed").last
        expect(event.user_id).to be_nil
        expect(event.metadata["reason"]).to eq("invalid_or_expired")
      end
    end

    context "with an expired token" do
      let(:user)  { create(:user, :unconfirmed) }
      let(:token) do
        travel_to(25.hours.ago) { user.generate_token_for(:email_confirmation) }
      end

      it_behaves_like "a failed Result", code: :invalid_token

      it "leaves the user unconfirmed" do
        expect { result }.not_to change { user.reload.confirmed_at }
      end
    end

    context "when the email_address changed after the token was issued" do
      let(:user)  { create(:user, :unconfirmed) }
      let(:token) { user.generate_token_for(:email_confirmation) }

      before do
        token
        user.update!(email_address: "different@pipelinehq.test")
      end

      it_behaves_like "a failed Result", code: :invalid_token

      it "leaves the user unconfirmed" do
        expect { result }.not_to change { user.reload.confirmed_at }
      end
    end
  end
end
