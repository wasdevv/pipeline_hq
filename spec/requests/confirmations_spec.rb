# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Confirmations", type: :request do
  include ActiveJob::TestHelper

  describe "GET /confirmations/new" do
    it "renders the resend form" do
      get new_confirmation_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /confirmations" do
    let(:user) { create(:user, :unconfirmed) }

    it "always redirects to login with a neutral notice (no enumeration)" do
      perform_enqueued_jobs { post confirmations_path, params: { email_address: user.email_address } }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to include("Se a conta existir")
    end

    it "delivers a new confirmation email for an unconfirmed user" do
      expect {
        perform_enqueued_jobs { post confirmations_path, params: { email_address: user.email_address } }
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it "does not deliver email for an already-confirmed user" do
      confirmed = create(:user)
      expect {
        perform_enqueued_jobs { post confirmations_path, params: { email_address: confirmed.email_address } }
      }.not_to change { ActionMailer::Base.deliveries.size }
    end

    it "does not deliver email for an unknown email" do
      expect {
        perform_enqueued_jobs { post confirmations_path, params: { email_address: "ghost@pipelinehq.test" } }
      }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end

  describe "GET /confirmations/:token" do
    context "with a valid token for an unconfirmed user" do
      let(:user)  { create(:user, :unconfirmed) }
      let(:token) { user.generate_token_for(:email_confirmation) }

      it "confirms the user and redirects to login" do
        perform_enqueued_jobs { get confirmation_path(token: token) }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to include("Email confirmado")
        expect(user.reload.confirmed_at).to be_present
      end
    end

    context "with a token for an already-confirmed user" do
      let(:user)  { create(:user) }
      let(:token) { user.generate_token_for(:email_confirmation) }

      it "redirects to login with an already-confirmed notice" do
        perform_enqueued_jobs { get confirmation_path(token: token) }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to include("Email já confirmado")
      end
    end

    context "with an invalid token" do
      it "redirects to the resend form with an alert" do
        perform_enqueued_jobs { get confirmation_path(token: "not-a-real-token") }

        expect(response).to redirect_to(new_confirmation_path)
        expect(flash[:alert]).to include("Link inválido")
      end
    end
  end
end
