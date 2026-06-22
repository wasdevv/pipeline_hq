# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoFactor::GenerateBackupCodes do
  describe ".call" do
    subject(:codes) { described_class.call }

    it "returns BACKUP_CODE_COUNT codes" do
      expect(codes.size).to eq(User::BACKUP_CODE_COUNT)
    end

    it "returns 8-character lowercase hex strings" do
      expect(codes).to all(match(/\A[a-f0-9]{8}\z/))
    end

    it "returns unique codes across a single call" do
      expect(codes.uniq).to eq(codes)
    end

    it "returns different codes on each call" do
      expect(described_class.call).not_to eq(described_class.call)
    end
  end
end
