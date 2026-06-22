# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Passwords", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  describe "GET /passwords/new" do
    it "renders the reset request form" do
      get new_password_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /passwords" do
    it "always redirects to login with a neutral notice (anti-enumeration)" do
      perform_enqueued_jobs { post passwords_path, params: { email_address: user.email_address } }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to include("Se a conta existir")
    end

    it "delivers a reset email for a known user" do
      expect {
        perform_enqueued_jobs { post passwords_path, params: { email_address: user.email_address } }
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it "records a password_reset_requested AuthEvent for a known user" do
      expect {
        perform_enqueued_jobs { post passwords_path, params: { email_address: user.email_address } }
      }.to change { AuthEvent.where(kind: "password_reset_requested", user: user).count }.by(1)
    end

    it "is silent for an unknown email" do
      expect {
        perform_enqueued_jobs { post passwords_path, params: { email_address: "ghost@pipelinehq.test" } }
      }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end

  describe "GET /passwords/:token/edit" do
    context "with a valid token" do
      let(:token) { user.password_reset_token }

      it "renders the edit form" do
        get edit_password_path(token: token)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid token" do
      it "redirects to reset request with alert" do
        get edit_password_path(token: "not-a-real-token")
        expect(response).to redirect_to(new_password_path)
        expect(flash[:alert]).to include("inválido ou expirado")
      end
    end
  end

  describe "PATCH /passwords/:token" do
    let(:token) { user.password_reset_token }
    let(:new_password) { "NewStrong!2026Password" }

    context "with matching strong passwords" do
      it "updates the password, destroys all sessions, redirects to login" do
        Session.create!(user: user, ip_address: "1.1.1.1", user_agent: "A")

        expect {
          perform_enqueued_jobs do
            patch password_path(token: token), params: { password: new_password, password_confirmation: new_password }
          end
        }.to change { user.reload.sessions.count }.to(0)

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to include("Senha atualizada")
        expect(user.authenticate(new_password)).to be_truthy
      end

      it "records a password_reset_completed AuthEvent" do
        expect {
          perform_enqueued_jobs do
            patch password_path(token: token), params: { password: new_password, password_confirmation: new_password }
          end
        }.to change { AuthEvent.where(kind: "password_reset_completed", user: user).count }.by(1)
      end

      it "resets failed_attempts and locked_at" do
        user.update!(failed_attempts: 3, locked_at: Time.current)

        perform_enqueued_jobs do
          patch password_path(token: token), params: { password: new_password, password_confirmation: new_password }
        end

        expect(user.reload.failed_attempts).to eq(0)
        expect(user.locked_at).to be_nil
      end
    end

    context "with mismatched passwords" do
      it "redirects back to edit with alert" do
        patch password_path(token: token), params: { password: new_password, password_confirmation: "different" }
        expect(response).to redirect_to(edit_password_path(token))
        expect(flash[:alert]).to include("As senhas não coincidem")
      end
    end
  end
end
