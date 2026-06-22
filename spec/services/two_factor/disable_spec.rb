# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoFactor::Disable do
  include ActiveJob::TestHelper
  include_context "with a request double"

  describe ".call" do
    subject(:result) do
      perform_enqueued_jobs do
        described_class.call(user: user, request: request)
      end
    end

    let(:user) { create(:user, :with_2fa, :with_backup_codes) }

    it_behaves_like "a successful Result", code: :disabled

    it "returns the user as payload" do
      expect(result.payload).to eq(user)
    end

    it "clears otp_secret" do
      expect { result }.to change { user.reload.otp_secret }.to(nil)
    end

    it "clears otp_enabled_at" do
      expect { result }.to change { user.reload.otp_enabled_at }.to(nil)
    end

    it "clears otp_backup_codes" do
      expect { result }.to change { user.reload.otp_backup_codes }.to([])
    end

    it "flips User#otp_enabled? to false" do
      result
      expect(user.reload.otp_enabled?).to be(false)
    end

    it "records an otp_disabled AuthEvent linked to the user" do
      expect { result }.to change { AuthEvent.where(kind: "otp_disabled", user: user).count }.by(1)
    end
  end
end
