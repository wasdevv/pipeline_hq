# frozen_string_literal: true

require "rails_helper"

RSpec.describe "TwoFactors", type: :request do
  include ActiveJob::TestHelper

  let(:password) { AuthenticationHelpers::TEST_PASSWORD }
  let(:user)     { create(:user) }

  def sign_in
    perform_enqueued_jobs { post session_path, params: { email_address: user.email_address, password: password } }
  end

  def complete_2fa_login
    sign_in
    totp = ROTP::TOTP.new(user.otp_secret).now
    perform_enqueued_jobs { post two_factor_verify_path, params: { code: totp } }
  end

  def start_sudo
    perform_enqueued_jobs { post sudo_path, params: { password: password } }
  end

  describe "GET /two_factor" do
    context "when not authenticated" do
      it "redirects to login" do
        get two_factor_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated without sudo" do
      before { sign_in }

      it "redirects to sudo new" do
        get two_factor_path
        expect(response).to redirect_to(new_sudo_path)
      end
    end

    context "when authenticated with sudo" do
      before { sign_in; start_sudo }

      it "renders the 2FA settings page" do
        get two_factor_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /two_factor/enroll" do
    before { sign_in; start_sudo }

    it "renders the enrollment page with secret and QR" do
      get enroll_two_factor_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<svg")
      expect(session[:pending_otp_secret]).to be_present
    end
  end

  describe "POST /two_factor/enroll (confirm)" do
    before { sign_in; start_sudo; get enroll_two_factor_path }

    context "with a valid TOTP" do
      let(:secret) { session[:pending_otp_secret] }

      it "activates 2FA and renders backup codes" do
        post enroll_two_factor_path, params: { code: ROTP::TOTP.new(secret).now }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Backup codes")
        expect(user.reload.otp_enabled_at).to be_present
      end
    end

    context "with an invalid TOTP" do
      it "redirects back to enroll with an alert" do
        post enroll_two_factor_path, params: { code: "000000" }

        expect(response).to redirect_to(enroll_two_factor_path)
        expect(flash[:alert]).to include("Código inválido")
      end
    end

    context "when session secret is missing" do
      before { reset_session }

      it "redirects back to enroll asking to restart" do
        post enroll_two_factor_path, params: { code: "000000" }
        expect(response).to redirect_to(new_session_path)
      end

      private

      def reset_session
        delete session_path
      end
    end
  end

  describe "POST /two_factor/verify (consume)" do
    let(:user) { create(:user, :with_2fa) }

    before { sign_in }

    context "with a valid TOTP" do
      it "verifies, creates a fresh session, redirects to root" do
        totp = ROTP::TOTP.new(user.otp_secret).now
        perform_enqueued_jobs { post two_factor_verify_path, params: { code: totp } }

        expect(response).to redirect_to(root_url)
      end
    end

    context "with an invalid TOTP" do
      it "redirects back to verify with alert" do
        perform_enqueued_jobs { post two_factor_verify_path, params: { code: "000000" } }

        expect(response).to redirect_to(two_factor_verify_path)
        expect(flash[:alert]).to include("Código inválido")
      end
    end
  end

  describe "DELETE /two_factor" do
    let(:user) { create(:user, :with_2fa, :with_backup_codes) }

    before { complete_2fa_login; start_sudo }

    it "disables 2FA and redirects to two_factor index" do
      delete two_factor_path
      expect(response).to redirect_to(two_factor_path)
      expect(user.reload.otp_enabled_at).to be_nil
    end
  end

  describe "POST /two_factor/backup_codes" do
    let(:user) { create(:user, :with_2fa, :with_backup_codes) }

    before { complete_2fa_login; start_sudo }

    it "regenerates backup codes and renders them" do
      post backup_codes_two_factor_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Backup codes")
    end
  end
end
