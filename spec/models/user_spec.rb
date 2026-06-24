# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
    it { is_expected.to have_many(:auth_events).dependent(:nullify).inverse_of(:user) }

    it { is_expected.to have_many(:workspace_memberships).dependent(:destroy).inverse_of(:user) }
    it { is_expected.to have_many(:workspaces).through(:workspace_memberships) }
    it { is_expected.to have_many(:owned_workspaces).class_name("Workspace").dependent(:restrict_with_error) }
    it { is_expected.to belong_to(:current_workspace).class_name("Workspace").optional }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(120) }

    it "rejects malformed email addresses" do
      user = build(:user, email_address: "not-an-email")
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to be_present
    end

    it "rejects weak passwords" do
      user = build(:user, password: "short", password_confirmation: "short")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end
  end

  describe "normalization" do
    it "downcases and strips email_address" do
      user = build(:user, email_address: "  Maria.SOUZA@PipelineHQ.test  ")
      user.valid?
      expect(user.email_address).to eq("maria.souza@pipelinehq.test")
    end
  end

  describe "constants" do
    it "freezes LOCK_THRESHOLD and LOCK_DURATION" do
      expect(User::LOCK_THRESHOLD).to eq(5)
      expect(User::LOCK_DURATION).to eq(15.minutes)
    end

    it "freezes BACKUP_CODE_COUNT" do
      expect(User::BACKUP_CODE_COUNT).to eq(8)
    end
  end

  describe "scopes" do
    let!(:confirmed_user)   { create(:user) }
    let!(:unconfirmed_user) { create(:user, :unconfirmed) }
    let!(:locked_user)      { create(:user, :locked) }
    let!(:expired_lock)     { create(:user, locked_at: (User::LOCK_DURATION + 1.minute).ago, failed_attempts: User::LOCK_THRESHOLD) }

    describe ".confirmed" do
      it "includes users with confirmed_at set" do
        expect(User.confirmed).to include(confirmed_user, locked_user, expired_lock)
        expect(User.confirmed).not_to include(unconfirmed_user)
      end
    end

    describe ".unconfirmed" do
      it "includes only users with confirmed_at nil" do
        expect(User.unconfirmed).to contain_exactly(unconfirmed_user)
      end
    end

    describe ".locked" do
      it "includes only users currently within the lock window" do
        expect(User.locked).to contain_exactly(locked_user)
      end

      it "excludes users whose lock has expired" do
        expect(User.locked).not_to include(expired_lock)
      end
    end
  end

  describe "predicates" do
    describe "#confirmed?" do
      it "returns true when confirmed_at is set" do
        expect(build(:user)).to be_confirmed
      end

      it "returns false when confirmed_at is nil" do
        expect(build(:user, :unconfirmed)).not_to be_confirmed
      end
    end

    describe "#locked?" do
      it "returns true within the lock window" do
        expect(build(:user, :locked)).to be_locked
      end

      it "returns false when locked_at is nil" do
        expect(build(:user)).not_to be_locked
      end

      it "returns false when the lock window has passed" do
        user = build(:user, locked_at: (User::LOCK_DURATION + 1.minute).ago)
        expect(user).not_to be_locked
      end
    end

    describe "#otp_enabled?" do
      it "returns true when otp_enabled_at is set" do
        expect(build(:user, :with_2fa)).to be_otp_enabled
      end

      it "returns false when otp_enabled_at is nil" do
        expect(build(:user)).not_to be_otp_enabled
      end
    end
  end

  describe "token generation" do
    it "generates an :email_confirmation token bound to email_address" do
      user = create(:user)
      token = user.generate_token_for(:email_confirmation)

      found = User.find_by_token_for(:email_confirmation, token)
      expect(found).to eq(user)
    end

    it "invalidates the token when the email_address changes" do
      user = create(:user)
      token = user.generate_token_for(:email_confirmation)

      user.update!(email_address: "different@pipelinehq.test")

      expect(User.find_by_token_for(:email_confirmation, token)).to be_nil
    end

    it "expires the token after 24 hours" do
      user = create(:user)
      token = travel_to(25.hours.ago) { user.generate_token_for(:email_confirmation) }

      expect(User.find_by_token_for(:email_confirmation, token)).to be_nil
    end
  end

  describe "AR encryption on otp_secret" do
    it "encrypts the otp_secret at rest" do
      secret = ROTP::Base32.random
      user   = create(:user, otp_secret: secret)

      raw = ActiveRecord::Base.connection.execute(
        "SELECT otp_secret FROM users WHERE id = #{user.id}"
      ).first["otp_secret"]

      expect(raw).not_to eq(secret)
      expect(user.reload.otp_secret).to eq(secret)
    end
  end
end
