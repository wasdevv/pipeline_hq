# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::TouchActivity do
  describe ".call" do
    let(:user) { create(:user) }

    context "with a nil session" do
      it "is a no-op" do
        expect { described_class.call(nil) }.not_to raise_error
      end
    end

    context "with a session that has never been touched" do
      let(:session) { Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "RSpec") }

      it "stamps last_active_at" do
        expect { described_class.call(session) }
          .to change { session.reload.last_active_at }.from(nil)
      end
    end

    context "with a session touched within the throttle window" do
      let(:original) { 30.seconds.ago }
      let(:session) do
        Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "RSpec", last_active_at: original)
      end

      it "does not update last_active_at" do
        described_class.call(session)
        expect(session.reload.last_active_at).to be_within(1.second).of(original)
      end
    end

    context "with a session touched outside the throttle window" do
      let(:session) do
        Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "RSpec", last_active_at: 5.minutes.ago)
      end

      it "refreshes last_active_at to ~now" do
        described_class.call(session)
        expect(session.reload.last_active_at).to be_within(5.seconds).of(Time.current)
      end
    end
  end
end
