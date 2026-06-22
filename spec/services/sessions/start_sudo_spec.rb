# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::StartSudo do
  include ActiveJob::TestHelper
  include_context "with a request double"

  describe ".call" do
    subject(:result) do
      perform_enqueued_jobs do
        described_class.call(session: user_session, password: password, request: request)
      end
    end

    let(:user)         { create(:user) }
    let(:user_session) { Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "RSpec") }

    context "with the correct password" do
      let(:password) { AuthenticationHelpers::TEST_PASSWORD }

      it_behaves_like "a successful Result", code: :sudo_started

      it "returns the session as payload" do
        expect(result.payload).to eq(user_session)
      end

      it "sets sudo_until ~15 minutes in the future" do
        result
        expect(user_session.reload.sudo_until).to be_within(5.seconds).of(15.minutes.from_now)
      end

      it "flips Session#sudo? to true" do
        result
        expect(user_session.reload).to be_sudo
      end

      it "records a sudo_started AuthEvent linked to the user" do
        expect { result }.to change { AuthEvent.where(kind: "sudo_started", user: user).count }.by(1)
      end
    end

    context "with the wrong password" do
      let(:password) { "WrongPass!9999" }

      it_behaves_like "a failed Result", code: :invalid_password

      it "does not set sudo_until" do
        expect { result }.not_to change { user_session.reload.sudo_until }
      end

      it "does not record any AuthEvent" do
        expect { result }.not_to change(AuthEvent, :count)
      end
    end

    context "when sudo is already active" do
      let(:password) { AuthenticationHelpers::TEST_PASSWORD }

      before { user_session.update!(sudo_until: 5.minutes.from_now) }

      it "refreshes sudo_until to the full 15-minute window" do
        result
        expect(user_session.reload.sudo_until).to be_within(5.seconds).of(15.minutes.from_now)
      end
    end
  end
end
