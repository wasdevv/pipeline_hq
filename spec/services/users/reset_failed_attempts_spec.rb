# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::ResetFailedAttempts do
  describe ".call" do
    context "when the user has failed attempts" do
      let(:user) { create(:user, failed_attempts: 3) }

      it "resets failed_attempts to zero" do
        expect { described_class.call(user: user) }
          .to change { user.reload.failed_attempts }.from(3).to(0)
      end
    end

    context "when the user is locked" do
      let(:user) { create(:user, :locked) }

      it "clears locked_at" do
        expect { described_class.call(user: user) }
          .to change { user.reload.locked_at }.to(nil)
      end

      it "also resets failed_attempts" do
        expect { described_class.call(user: user) }
          .to change { user.reload.failed_attempts }.to(0)
      end
    end

    context "when the user has no failed attempts and is not locked" do
      let(:user) { create(:user, failed_attempts: 0) }

      it "does not issue an UPDATE" do
        expect { described_class.call(user: user) }
          .not_to change { user.reload.updated_at }
      end
    end
  end
end
