# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SessionsManagement", type: :request do
  include ActiveJob::TestHelper

  let(:password) { AuthenticationHelpers::TEST_PASSWORD }
  let(:user)     { create(:user) }

  before do
    perform_enqueued_jobs { post session_path, params: { email_address: user.email_address, password: password } }
  end

  describe "GET /sessions_management" do
    it "lists the current user's sessions" do
      get sessions_management_index_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /sessions_management/:id" do
    let!(:other_session) do
      Session.create!(user: user, ip_address: "10.0.0.1", user_agent: "Other Browser")
    end

    it "revokes the targeted session" do
      expect {
        perform_enqueued_jobs { delete sessions_management_destroy_path(id: other_session.id) }
      }.to change { Session.where(id: other_session.id).count }.by(-1)

      expect(response).to redirect_to(sessions_management_index_path)
    end

    it "records a session_revoked AuthEvent" do
      expect {
        perform_enqueued_jobs { delete sessions_management_destroy_path(id: other_session.id) }
      }.to change { AuthEvent.where(kind: "session_revoked", user: user).count }.by(1)
    end

    it "returns 404 for a session not owned by current_user" do
      other_user_session = Session.create!(user: create(:user), ip_address: "10.0.0.2", user_agent: "Stranger")

      delete sessions_management_destroy_path(id: other_user_session.id)
      expect(response).to have_http_status(:not_found)
      expect(Session.exists?(other_user_session.id)).to be(true)
    end
  end

  describe "DELETE /sessions_management (destroy_all)" do
    let!(:other_session_1) { Session.create!(user: user, ip_address: "10.0.0.1", user_agent: "A") }
    let!(:other_session_2) { Session.create!(user: user, ip_address: "10.0.0.2", user_agent: "B") }

    it "revokes all sessions except the current one" do
      expect {
        perform_enqueued_jobs { delete sessions_management_destroy_all_path }
      }.to change { user.sessions.count }.by(-2)

      expect(response).to redirect_to(sessions_management_index_path)
    end

    it "records a sessions_revoked_all AuthEvent" do
      expect {
        perform_enqueued_jobs { delete sessions_management_destroy_all_path }
      }.to change { AuthEvent.where(kind: "sessions_revoked_all", user: user).count }.by(1)
    end
  end
end
