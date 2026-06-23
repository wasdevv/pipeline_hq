# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SudoSessions", type: :request do
  include ActiveJob::TestHelper

  let(:password) { AuthenticationHelpers::TEST_PASSWORD }
  let(:user)     { create(:user) }

  before do
    perform_enqueued_jobs { post session_path, params: { email_address: user.email_address, password: password } }
  end

  describe "GET /sudo/new" do
    it "renders the sudo password prompt" do
      get new_sudo_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Modo seguro")
    end
  end

  describe "POST /sudo" do
    context "with the correct password" do
      it "starts sudo and redirects to root by default" do
        perform_enqueued_jobs { post sudo_path, params: { password: password } }
        expect(response).to redirect_to(root_url)
        expect(flash[:notice]).to include("Modo seguro ativo")
      end

      it "redirects to sudo_return_to when set in session" do
        get enroll_two_factor_path
        perform_enqueued_jobs { post sudo_path, params: { password: password } }
        expect(response).to redirect_to(enroll_two_factor_url)
      end
    end

    context "with the wrong password" do
      it "redirects back to sudo new with alert" do
        perform_enqueued_jobs { post sudo_path, params: { password: "wrong-pw" } }
        expect(response).to redirect_to(new_sudo_path)
        expect(flash[:alert]).to include("Senha incorreta")
      end
    end
  end
end
