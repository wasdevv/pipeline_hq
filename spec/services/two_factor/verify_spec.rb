# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoFactor::Verify do
  include ActiveJob::TestHelper
  include_context "with a request double"

  describe ".call" do
    subject(:result) do
      perform_enqueued_jobs do
        described_class.call(user: user, code: code, request: request)
      end
    end

    let(:user) { create(:user, :with_2fa) }

    context "with a valid TOTP code" do
      let(:code) { ROTP::TOTP.new(user.otp_secret).now }

      it_behaves_like "a successful Result", code: :verified

      it "returns the user as payload" do
        expect(result.payload).to eq(user)
      end

      it "records an otp_verified AuthEvent linked to the user" do
        expect { result }.to change { AuthEvent.where(kind: "otp_verified", user: user).count }.by(1)
      end

      it "does not record otp_failed or backup_code_used" do
        expect { result }.not_to change { AuthEvent.where(kind: %w[otp_failed backup_code_used]).count }
      end
    end

    context "with whitespace and casing around a valid TOTP" do
      let(:code) { "  #{ROTP::TOTP.new(user.otp_secret).now}  " }

      it_behaves_like "a successful Result", code: :verified
    end

    context "with a valid backup code" do
      let(:plain_code)     { "abcd-1234" }
      let(:secondary_code) { "wxyz-9999" }

      before do
        user.update!(otp_backup_codes: [
          BCrypt::Password.create(plain_code),
          BCrypt::Password.create(secondary_code)
        ])
      end

      let(:code) { plain_code }

      it_behaves_like "a successful Result", code: :verified

      it "records a backup_code_used AuthEvent linked to the user" do
        expect { result }.to change { AuthEvent.where(kind: "backup_code_used", user: user).count }.by(1)
      end

      it "removes the matched backup code from the user" do
        expect { result }.to change { user.reload.otp_backup_codes.size }.from(2).to(1)
      end

      it "keeps unmatched backup codes intact" do
        result
        remaining = user.reload.otp_backup_codes
        expect(BCrypt::Password.new(remaining.first) == secondary_code).to be(true)
      end

      it "cannot consume the same backup code twice" do
        perform_enqueued_jobs { described_class.call(user: user, code: code, request: request) }
        second_attempt = described_class.call(user: user, code: code, request: request)

        expect(second_attempt).to be_failure
        expect(second_attempt.code).to eq(:invalid_code)
      end
    end

    context "with an invalid code (neither TOTP nor backup)" do
      let(:code) { "000000" }

      it_behaves_like "a failed Result", code: :invalid_code

      it "records an otp_failed AuthEvent linked to the user" do
        expect { result }.to change { AuthEvent.where(kind: "otp_failed", user: user).count }.by(1)
      end

      it "does not consume any backup codes" do
        user.update!(otp_backup_codes: [ BCrypt::Password.create("real-code") ])
        expect { result }.not_to change { user.reload.otp_backup_codes.size }
      end
    end

    context "when the user has no backup codes and the TOTP is wrong" do
      let(:code) { "999999" }

      it_behaves_like "a failed Result", code: :invalid_code

      it "records an otp_failed AuthEvent" do
        expect { result }.to change { AuthEvent.where(kind: "otp_failed", user: user).count }.by(1)
      end
    end
  end
end
