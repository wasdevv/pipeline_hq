# frozen_string_literal: true

require "rails_helper"

RSpec.describe Session, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user).inverse_of(:sessions) }
  end

  describe "constants" do
    it "defines TOUCH_THROTTLE, IDLE_EXPIRY, SUDO_DURATION" do
      expect(Session::TOUCH_THROTTLE).to eq(1.minute)
      expect(Session::IDLE_EXPIRY).to eq(14.days)
      expect(Session::SUDO_DURATION).to eq(15.minutes)
    end
  end

  describe "scopes" do
    let(:user)         { create(:user) }
    let!(:fresh)       { Session.create!(user: user, ip_address: "1.1.1.1", user_agent: "u", last_active_at: 1.minute.ago) }
    let!(:never_touched) { Session.create!(user: user, ip_address: "1.1.1.2", user_agent: "u", last_active_at: nil) }
    let!(:idle)        { Session.create!(user: user, ip_address: "1.1.1.3", user_agent: "u", last_active_at: (Session::IDLE_EXPIRY + 1.day).ago) }

    describe ".active" do
      it "includes sessions touched within IDLE_EXPIRY or never touched" do
        expect(Session.active).to include(fresh, never_touched)
        expect(Session.active).not_to include(idle)
      end
    end

    describe ".idle" do
      it "includes only sessions touched past IDLE_EXPIRY" do
        expect(Session.idle).to contain_exactly(idle)
      end
    end

    describe ".except_current" do
      it "excludes the given session" do
        expect(Session.except_current(fresh)).to contain_exactly(never_touched, idle)
      end
    end

    describe ".by_recency" do
      it "orders sessions with timestamps by last_active_at desc" do
        ordered = Session.where(user: user).where.not(last_active_at: nil).by_recency.to_a
        expect(ordered).to eq([ fresh, idle ])
      end
    end
  end

  describe "predicates" do
    let(:user) { create(:user) }
    let(:session) { Session.create!(user: user, ip_address: "1.1.1.1", user_agent: "u") }

    describe "#sudo?" do
      it "returns true when sudo_until is in the future" do
        session.update!(sudo_until: 10.minutes.from_now)
        expect(session).to be_sudo
      end

      it "returns false when sudo_until is nil" do
        expect(session).not_to be_sudo
      end

      it "returns false when sudo_until is in the past" do
        session.update!(sudo_until: 1.minute.ago)
        expect(session).not_to be_sudo
      end
    end

    describe "#otp_verified?" do
      it "returns true when otp_verified_at is set" do
        session.update!(otp_verified_at: Time.current)
        expect(session).to be_otp_verified
      end

      it "returns false when otp_verified_at is nil" do
        expect(session).not_to be_otp_verified
      end
    end
  end
end
