# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::SignIn do
  include ActiveJob::TestHelper
  include_context "with a request double"

  describe ".call" do
    subject(:result) do
      perform_enqueued_jobs do
        described_class.call(email_address: email_address, password: password, request: request)
      end
    end

    let(:password) { AuthenticationHelpers::TEST_PASSWORD }

    context "with valid credentials, confirmed account, and no 2FA" do
      let(:user)          { create(:user, failed_attempts: 2) }
      let(:email_address) { user.email_address }

      it_behaves_like "a successful Result", code: :signed_in

      it "returns the user as payload" do
        expect(result.payload).to eq(user)
      end

      it "resets failed_attempts to zero" do
        expect { result }.to change { user.reload.failed_attempts }.from(2).to(0)
      end

      it "records a login_success AuthEvent linked to the user" do
        expect { result }.to change { AuthEvent.where(kind: "login_success", user: user).count }.by(1)
      end

      it "stores ip_address and user_agent on the AuthEvent" do
        result
        event = AuthEvent.where(kind: "login_success", user: user).last
        expect(event.ip_address).to eq("127.0.0.1")
        expect(event.user_agent).to eq("RSpec/TestAgent")
      end
    end

    context "with unknown email" do
      let(:email_address) { "ghost@pipelinehq.test" }

      it_behaves_like "a failed Result", code: :invalid_credentials

      it "records a login_failed AuthEvent with the attempted email and no user" do
        expect { result }.to change { AuthEvent.where(kind: "login_failed", user_id: nil).count }.by(1)

        event = AuthEvent.where(kind: "login_failed", user_id: nil).last
        expect(event.email_address).to eq(email_address)
      end

      it "does not increment failed_attempts on any user" do
        create(:user)
        expect { result }.not_to change { User.maximum(:failed_attempts) }
      end
    end

    context "with a known email and wrong password" do
      let(:user)          { create(:user) }
      let(:email_address) { user.email_address }
      let(:password)      { "WrongPass!999" }

      it_behaves_like "a failed Result", code: :invalid_credentials

      it "increments failed_attempts on the user" do
        expect { result }.to change { user.reload.failed_attempts }.by(1)
      end

      it "records a login_failed AuthEvent linked to the user" do
        expect { result }.to change { AuthEvent.where(kind: "login_failed", user: user).count }.by(1)
      end
    end

    context "when the user is locked out" do
      let(:user)          { create(:user, :locked) }
      let(:email_address) { user.email_address }

      it_behaves_like "a failed Result", code: :locked

      it "does not create any AuthEvent" do
        expect { result }.not_to change { AuthEvent.count }
      end

      it "does not change failed_attempts" do
        expect { result }.not_to change { user.reload.failed_attempts }
      end
    end

    context "with an unconfirmed email" do
      let(:user)          { create(:user, :unconfirmed) }
      let(:email_address) { user.email_address }

      it_behaves_like "a failed Result", code: :unconfirmed

      it "does not create any AuthEvent" do
        expect { result }.not_to change { AuthEvent.count }
      end

      it "does not change failed_attempts" do
        expect { result }.not_to change { user.reload.failed_attempts }
      end
    end

    context "when OTP is enabled (2FA required)" do
      let(:user)          { create(:user, :with_2fa) }
      let(:email_address) { user.email_address }

      it_behaves_like "a successful Result", code: :requires_otp

      it "returns the user as payload" do
        expect(result.payload).to eq(user)
      end

      it "does not create any AuthEvent at this stage" do
        expect { result }.not_to change { AuthEvent.count }
      end

      it "does not reset failed_attempts at this stage" do
        user.update!(failed_attempts: 3)
        result
        expect(user.reload.failed_attempts).to eq(3)
      end
    end
  end
end
