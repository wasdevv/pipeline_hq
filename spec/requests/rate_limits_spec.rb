# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth rate limits", type: :request do
  include ActiveJob::TestHelper

  shared_examples "a throttled endpoint" do |label:, hits:|
    it "redirects with a throttling alert after #{hits} hits in the window" do
      (hits + 1).times { perform_request }

      expect(response).to redirect_to(redirect_target)
      expect(flash[:alert]).to include(label)
    end
  end

  describe "POST /session" do
    let(:redirect_target) { new_session_path }
    let(:user)            { create(:user) }

    def perform_request(index = 0)
      post session_path,
        params: { email_address: "drip#{index}@pipelinehq.test", password: "wrong" }
    end

    it "redirects with the controller throttling alert after 10 hits in the window" do
      11.times.each { |i| perform_request(i) }

      expect(response).to redirect_to(redirect_target)
      expect(flash[:alert]).to include("alguns minutos")
    end
  end

  describe "POST /sign_up" do
    def perform_request(index)
      post registration_path, params: {
        user: {
          name: "Bot #{index}",
          email_address: "bot#{index}@pipelinehq.test",
          password: AuthenticationHelpers::TEST_PASSWORD,
          password_confirmation: AuthenticationHelpers::TEST_PASSWORD
        }
      }, env: { "REMOTE_ADDR" => "10.0.0.5" }
    end

    it "is throttled by rack-attack signups/ip before reaching the controller layer" do
      11.times.each { |i| perform_request(i) }

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "POST /confirmations" do
    let(:redirect_target) { new_confirmation_path }

    def perform_request
      post confirmations_path, params: { email_address: "noone@pipelinehq.test" }
    end

    it_behaves_like "a throttled endpoint", label: "alguns minutos", hits: 10
  end

  describe "POST /passwords" do
    def perform_request(index)
      post passwords_path,
        params: { email_address: "ghost#{index}@pipelinehq.test" },
        env: { "REMOTE_ADDR" => "10.0.1.5" }
    end

    it "is throttled by rack-attack passwords/ip before reaching the controller layer" do
      11.times.each { |i| perform_request(i) }

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "POST /sudo" do
    let(:redirect_target) { new_sudo_path }
    let(:user)            { create(:user) }

    before do
      perform_enqueued_jobs do
        post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
      end
    end

    def perform_request
      post sudo_path, params: { password: "wrong" }
    end

    it_behaves_like "a throttled endpoint", label: "alguns minutos", hits: 10
  end

  describe "POST /two_factor/verify" do
    let(:redirect_target) { new_session_path }

    def perform_request
      post two_factor_verify_path, params: { code: "000000" }
    end

    it_behaves_like "a throttled endpoint", label: "Muitas tentativas", hits: 5
  end
end
