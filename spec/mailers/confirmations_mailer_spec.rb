# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConfirmationsMailer, type: :mailer do
  describe "#confirm" do
    let(:user)  { create(:user, :unconfirmed) }
    let(:token) { user.generate_token_for(:email_confirmation) }
    let(:mail)  { described_class.confirm(user, token) }

    it "addresses the user's email" do
      expect(mail.to).to eq([ user.email_address ])
    end

    it "uses a pt-BR subject" do
      expect(mail.subject).to eq("Confirme seu email — PipelineHQ")
    end

    it "includes a /confirmations/ link in the body" do
      expect(mail.body.encoded).to include("/confirmations/")
    end

    it "is deliverable" do
      expect { mail.deliver_now }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end
end
