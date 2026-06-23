# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::Register do
  include ActiveJob::TestHelper
  include_context "with a request double"

  describe ".call" do
    subject(:result) do
      perform_enqueued_jobs do
        described_class.call(params: params, request: request)
      end
    end

    let(:valid_params) do
      {
        name:                  "Maria Souza",
        email_address:         "maria@pipelinehq.test",
        password:              AuthenticationHelpers::TEST_PASSWORD,
        password_confirmation: AuthenticationHelpers::TEST_PASSWORD
      }
    end

    context "with valid params" do
      let(:params) { valid_params }

      it_behaves_like "a successful Result", code: :registered

      it "persists the user" do
        expect { result }.to change(User, :count).by(1)
      end

      it "returns the persisted user as payload" do
        expect(result.payload).to be_a(User).and be_persisted
        expect(result.payload.email_address).to eq("maria@pipelinehq.test")
      end

      it "leaves the user unconfirmed" do
        expect(result.payload.confirmed_at).to be_nil
      end

      it "stamps confirmation_sent_at" do
        expect(result.payload.reload.confirmation_sent_at).to be_within(5.seconds).of(Time.current)
      end

      it "delivers the confirmation email" do
        expect { result }.to change { ActionMailer::Base.deliveries.size }.by(1)
        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to eq([ "maria@pipelinehq.test" ])
      end

      it "records a signup AuthEvent linked to the user" do
        expect { result }.to change { AuthEvent.where(kind: "signup").count }.by(1)

        event = AuthEvent.where(kind: "signup").last
        expect(event.user_id).to eq(result.payload.id)
        expect(event.ip_address).to eq("127.0.0.1")
        expect(event.user_agent).to eq("RSpec/TestAgent")
      end

      it "records an email_confirmation_sent AuthEvent" do
        expect { result }.to change { AuthEvent.where(kind: "email_confirmation_sent").count }.by(1)
      end
    end

    context "with a duplicate email address" do
      let(:params) { valid_params }

      before { create(:user, email_address: "maria@pipelinehq.test") }

      it_behaves_like "a failed Result", code: :invalid

      it "exposes the validation errors" do
        expect(result.errors[:email_address]).to be_present
      end

      it "returns an unsaved user as payload" do
        expect(result.payload).to be_a(User)
        expect(result.payload).not_to be_persisted
      end

      it "does not create a new user" do
        expect { result }.not_to change(User, :count)
      end

      it "does not deliver a confirmation email" do
        expect { result }.not_to change { ActionMailer::Base.deliveries.size }
      end

      it "does not record any AuthEvent" do
        expect { result }.not_to change(AuthEvent, :count)
      end
    end

    context "with a weak password" do
      let(:params) { valid_params.merge(password: "weak", password_confirmation: "weak") }

      it_behaves_like "a failed Result", code: :invalid

      it "exposes the password error" do
        expect(result.errors[:password]).to be_present
      end

      it "does not create a user" do
        expect { result }.not_to change(User, :count)
      end
    end

    context "with mismatched password confirmation" do
      let(:params) { valid_params.merge(password_confirmation: "DifferentPass!2026") }

      it_behaves_like "a failed Result", code: :invalid

      it "exposes the password_confirmation error" do
        expect(result.errors[:password_confirmation]).to be_present
      end
    end
  end
end
