# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication concern helpers", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  describe "authenticated? helper" do
    it "returns false before a session is established" do
      get new_session_path
      expect(controller.send(:authenticated?)).to be(false)
    end

    it "returns true after a successful login" do
      perform_enqueued_jobs do
        post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
      end
      get root_path
      expect(controller.send(:authenticated?)).to be(true)
    end
  end
end
