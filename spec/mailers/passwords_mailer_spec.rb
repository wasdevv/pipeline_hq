# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  describe "#reset" do
    let(:user) { create(:user) }
    let(:mail) { described_class.reset(user) }

    it "addresses the user's email" do
      expect(mail.to).to eq([ user.email_address ])
    end

    it "has a subject" do
      expect(mail.subject).to be_present
    end

    it "is deliverable" do
      expect { mail.deliver_now }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end
end
