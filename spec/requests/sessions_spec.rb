# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  include ActiveJob::TestHelper

  let(:password) { AuthenticationHelpers::TEST_PASSWORD }

  describe "GET /session/new" do
    it "renders the login form" do
      get new_session_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sign in")
    end
  end

  describe "POST /session" do
    context "with valid credentials and no 2FA" do
      let(:user) { create(:user) }

      it "creates a session and redirects to root" do
        expect {
          perform_enqueued_jobs { post session_path, params: { email_address: user.email_address, password: password } }
        }.to change(Session, :count).by(1)

        expect(response).to redirect_to(root_url)
      end
    end

    context "with valid credentials and 2FA enabled" do
      let(:user) { create(:user, :with_2fa) }

      it "stores pending_otp_user_id and redirects to two_factor_verify" do
        perform_enqueued_jobs { post session_path, params: { email_address: user.email_address, password: password } }

        expect(response).to redirect_to(two_factor_verify_path)
        expect(session[:pending_otp_user_id]).to eq(user.id)
      end
    end

    context "with invalid credentials" do
      let(:user) { create(:user) }

      it "redirects back to login with a generic alert" do
        perform_enqueued_jobs { post session_path, params: { email_address: user.email_address, password: "wrong-pw" } }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to include("Email ou senha inválidos")
      end
    end

    context "with a locked user" do
      let(:user) { create(:user, :locked) }

      it "redirects to login with the generic alert (no enumeration)" do
        perform_enqueued_jobs { post session_path, params: { email_address: user.email_address, password: password } }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to include("Email ou senha inválidos")
      end
    end

    context "with an unconfirmed user" do
      let(:user) { create(:user, :unconfirmed) }

      it "redirects to login with the generic alert" do
        perform_enqueued_jobs { post session_path, params: { email_address: user.email_address, password: password } }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to include("Email ou senha inválidos")
      end
    end
  end

  describe "DELETE /session" do
    let(:user) { create(:user) }

    before do
      perform_enqueued_jobs { post session_path, params: { email_address: user.email_address, password: password } }
    end

    it "terminates the session and redirects to login" do
      expect { delete session_path }.to change(Session, :count).by(-1)
      expect(response).to redirect_to(new_session_path)
      expect(response).to have_http_status(:see_other)
    end
  end
end
