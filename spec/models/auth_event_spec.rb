# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthEvent, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user).optional.inverse_of(:auth_events) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:kind) }
    it { is_expected.to validate_inclusion_of(:kind).in_array(AuthEvent::KINDS) }
  end

  describe "KINDS" do
    it "is frozen" do
      expect(AuthEvent::KINDS).to be_frozen
    end

    it "is a non-empty list of string kinds" do
      expect(AuthEvent::KINDS).to be_an(Array)
      expect(AuthEvent::KINDS).to all(be_a(String))
      expect(AuthEvent::KINDS).not_to be_empty
    end

    it "includes every kind emitted by the auth services" do
      emitted = %w[
        signup
        email_confirmation_sent email_confirmation_failed email_confirmed
        login_success login_failed
        account_locked
        otp_enrolled otp_disabled otp_verified otp_failed
        backup_code_used backup_codes_regenerated
        sudo_started honeypot_triggered
      ]
      expect(AuthEvent::KINDS).to include(*emitted)
    end
  end

  describe ".recent scope" do
    it "orders by created_at desc" do
      older  = AuthEvent.create!(kind: "login_success", created_at: 2.days.ago)
      newer  = AuthEvent.create!(kind: "login_success", created_at: 1.minute.ago)

      expect(AuthEvent.recent.first).to eq(newer)
      expect(AuthEvent.recent.last).to eq(older)
    end
  end

  describe "inheritance_column" do
    it "is disabled (kind is not a STI discriminator)" do
      expect(AuthEvent.inheritance_column).to be_blank
    end

    it "allows creating records with arbitrary 'type'-like kinds without STI lookup" do
      expect { AuthEvent.create!(kind: "login_success") }.not_to raise_error
    end
  end

  describe "user association" do
    it "is optional (system-level events without a user)" do
      event = AuthEvent.new(kind: "honeypot_triggered", email_address: "bot@x.test")
      expect(event).to be_valid
    end

    it "nullifies user_id when the user is destroyed" do
      user  = create(:user)
      event = AuthEvent.create!(kind: "login_success", user: user)

      user.owned_workspaces.each { |w| w.workspace_memberships.delete_all; w.delete }
      user.reload.destroy!
      expect(event.reload.user_id).to be_nil
    end
  end
end
