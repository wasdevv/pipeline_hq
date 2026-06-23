# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoFactor::RegenerateBackupCodes do
  include ActiveJob::TestHelper
  include_context "with a request double"

  describe ".call" do
    subject(:result) do
      perform_enqueued_jobs do
        described_class.call(user: user, request: request)
      end
    end

    let(:user)           { create(:user, :with_2fa, :with_backup_codes, plain_codes: [ "old-code" ]) }
    let(:original_hashes) { user.otp_backup_codes.dup }

    it_behaves_like "a successful Result", code: :regenerated

    it "returns BACKUP_CODE_COUNT new codes in the payload" do
      codes = result.payload
      expect(codes.size).to eq(User::BACKUP_CODE_COUNT)
      expect(codes).to all(match(/\A[a-f0-9]{8}\z/))
    end

    it "replaces the existing backup codes with new bcrypt hashes" do
      original_hashes
      result
      stored = user.reload.otp_backup_codes

      expect(stored.size).to eq(User::BACKUP_CODE_COUNT)
      expect(stored & original_hashes).to be_empty
      expect(stored.first).to start_with("$2")
    end

    it "records a backup_codes_regenerated AuthEvent linked to the user" do
      expect { result }.to change { AuthEvent.where(kind: "backup_codes_regenerated", user: user).count }.by(1)
    end
  end
end
