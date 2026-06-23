# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoFactor::Enroll do
  describe ".call" do
    subject(:result) { described_class.call(user: user) }

    let(:user) { create(:user) }

    it_behaves_like "a successful Result", code: :enrolled

    it "returns a base32-encoded secret in the payload" do
      expect(result.payload[:secret]).to match(/\A[A-Z2-7]+\z/)
    end

    it "returns a provisioning URI scoped to PipelineHQ and the user email" do
      uri = result.payload[:uri]
      expect(uri).to start_with("otpauth://totp/")
      expect(uri).to include("issuer=PipelineHQ")
      expect(uri).to include(CGI.escape(user.email_address))
    end

    it "returns an SVG QR code in the payload" do
      qr = result.payload[:qr_svg]
      expect(qr).to start_with("<?xml")
      expect(qr).to include("<svg")
    end

    it "does not persist anything on the user yet" do
      expect { result }.not_to change { user.reload.otp_secret }
    end
  end
end
