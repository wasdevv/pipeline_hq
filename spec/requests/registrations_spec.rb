# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Registrations", type: :request do
  include ActiveJob::TestHelper

  let(:valid_params) do
    {
      user: {
        name:                  "Maria Souza",
        email_address:         "maria.req@pipelinehq.test",
        password:              AuthenticationHelpers::TEST_PASSWORD,
        password_confirmation: AuthenticationHelpers::TEST_PASSWORD
      }
    }
  end

  describe "GET /sign_up/new" do
    it "renders the signup form" do
      get new_registration_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Criar conta")
    end
  end

  describe "POST /sign_up" do
    context "with valid params" do
      it "creates the user and redirects to confirmation new" do
        expect {
          perform_enqueued_jobs { post registration_path, params: valid_params }
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(new_confirmation_path)
        expect(flash[:notice]).to include("Conta criada")
      end
    end

    context "when the honeypot field is filled" do
      it "fakes a success without creating a user" do
        expect {
          perform_enqueued_jobs do
            post registration_path, params: valid_params.merge(nickname: "spam-bot")
          end
        }.not_to change(User, :count)

        expect(response).to redirect_to(new_confirmation_path)
        expect(flash[:notice]).to include("Quase pronto")
      end

      it "records a honeypot_triggered AuthEvent" do
        expect {
          perform_enqueued_jobs do
            post registration_path, params: valid_params.merge(nickname: "spam-bot")
          end
        }.to change { AuthEvent.where(kind: "honeypot_triggered").count }.by(1)
      end
    end

    context "with invalid params" do
      it "re-renders the form with 422" do
        post registration_path, params: { user: valid_params[:user].merge(email_address: "not-an-email") }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Criar conta")
      end
    end
  end
end
