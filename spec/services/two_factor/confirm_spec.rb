# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoFactor::Confirm do
  include ActiveJob::TestHelper
  include_context "with a request double"

  describe ".call" do
    subject(:result) do
      perform_enqueued_jobs do
        described_class.call(user: user, secret: secret, code: code, request: request)
      end
    end

    let(:user)   { create(:user) }
    let(:secret) { ROTP::Base32.random }

    context "with a valid TOTP for the given secret" do
      let(:code) { ROTP::TOTP.new(secret).now }

      it_behaves_like "a successful Result", code: :enrolled

      it "persists the otp_secret on the user" do
        expect { result }.to change { user.reload.otp_secret }.from(nil).to(secret)
      end

      it "stamps otp_enabled_at" do
        expect { result }.to change { user.reload.otp_enabled_at }.from(nil)
      end

      it "returns BACKUP_CODE_COUNT backup codes in the payload" do
        codes = result.payload
        expect(codes.size).to eq(User::BACKUP_CODE_COUNT)
        expect(codes).to all(match(/\A[a-f0-9]{8}\z/))
      end

      it "stores backup codes as bcrypt hashes on the user" do
        codes = result.payload
        stored = user.reload.otp_backup_codes

        expect(stored.size).to eq(User::BACKUP_CODE_COUNT)
        expect(stored.first).to start_with("$2")
        expect(BCrypt::Password.new(stored.first) == codes.first).to be(true)
      end

      it "records an otp_enrolled AuthEvent linked to the user" do
        expect { result }.to change { AuthEvent.where(kind: "otp_enrolled", user: user).count }.by(1)
      end
    end

    context "with an invalid TOTP" do
      let(:code) { "000000" }

      it_behaves_like "a failed Result", code: :invalid_code

      it "does not persist anything on the user" do
        expect { result }.not_to change { user.reload.otp_secret }
        expect(user.otp_enabled_at).to be_nil
        expect(user.otp_backup_codes).to eq([])
      end

      it "does not record any AuthEvent" do
        expect { result }.not_to change(AuthEvent, :count)
      end
    end
  end
end
