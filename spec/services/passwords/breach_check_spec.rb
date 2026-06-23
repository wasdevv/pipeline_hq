# frozen_string_literal: true

require "rails_helper"

RSpec.describe Passwords::BreachCheck do
  describe ".call" do
    it "returns false for the strong test password (replayed cassette)" do
      expect(described_class.call(AuthenticationHelpers::TEST_PASSWORD)).to be(false)
    end

    it "fails open on Pwned::Error" do
      allow_any_instance_of(Pwned::Password).to receive(:pwned?).and_raise(Pwned::Error)

      expect(described_class.call("anything")).to be(false)
    end

    it "fails open on Net::OpenTimeout" do
      allow_any_instance_of(Pwned::Password).to receive(:pwned?).and_raise(Net::OpenTimeout)

      expect(described_class.call("anything")).to be(false)
    end

    it "fails open on Net::ReadTimeout" do
      allow_any_instance_of(Pwned::Password).to receive(:pwned?).and_raise(Net::ReadTimeout)

      expect(described_class.call("anything")).to be(false)
    end

    it "exposes TIMEOUT_SECONDS as a frozen constant" do
      expect(Passwords::BreachCheck::TIMEOUT_SECONDS).to eq(1)
    end
  end
end
