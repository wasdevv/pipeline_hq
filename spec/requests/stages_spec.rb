# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Stages", type: :request do
  include ActiveJob::TestHelper

  let(:user)      { create(:user) }
  let(:workspace) { user.current_workspace }
  let(:create_params) { { name: "New Stage", position: 100, color: "#000000" } }
  let(:update_params) { { name: "Updated Stage", position: 200, color: "#ffffff" } }

  before do
    perform_enqueued_jobs do
      post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  it_behaves_like "a standard scaffold",
    model: Stage,
    factory: :stage,
    attribute_path: "stages",
    skip_create: false do
    let(:record) { create(:stage, workspace: workspace) }
  end

  context "when persistence fails" do
    before { allow_any_instance_of(Stage).to receive(:save).and_return(false) }

    it "POST create re-renders the form with 422 (html)" do
      post stages_path, params: { stage: create_params }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "POST create returns 422 (json)" do
      post stages_path,
           params:  { stage: create_params }.to_json,
           headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context "when update fails" do
    let!(:existing) { create(:stage, workspace: workspace) }

    before { allow_any_instance_of(Stage).to receive(:update).and_return(false) }

    it "PATCH update re-renders the form with 422 (html)" do
      patch stage_path(existing), params: { stage: update_params }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "PATCH update returns 422 (json)" do
      patch stage_path(existing),
            params:  { stage: update_params }.to_json,
            headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "RecordsDomainEvents concern" do
    it "enqueues stage.created event on successful POST create" do
      expect {
        post stages_path, params: { stage: create_params }
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(kind: "stage.created")
      )
    end

    it "enqueues stage.updated event on successful PATCH update" do
      existing = create(:stage, workspace: workspace)
      expect {
        patch stage_path(existing), params: { stage: update_params }
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(kind: "stage.updated")
      )
    end

    it "enqueues stage.destroyed event on successful DELETE destroy" do
      existing = create(:stage, workspace: workspace)
      expect {
        delete stage_path(existing)
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(kind: "stage.destroyed")
      )
    end

    it "does NOT enqueue an event when create fails (save returns false)" do
      allow_any_instance_of(Stage).to receive(:save).and_return(false)
      expect {
        post stages_path, params: { stage: create_params }
      }.not_to have_enqueued_job(DomainEventJob)
    end
  end
end
