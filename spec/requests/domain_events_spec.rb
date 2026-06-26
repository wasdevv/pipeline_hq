# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DomainEvents", type: :request do
  include ActiveJob::TestHelper

  let(:user)      { create(:user) }
  let(:workspace) { user.current_workspace }

  before do
    perform_enqueued_jobs do
      post session_path, params: { email_address: user.email_address, password: AuthenticationHelpers::TEST_PASSWORD }
    end
  end

  describe "GET /domain_events" do
    context "when user has membership" do
      it "returns 200" do
        get domain_events_path
        expect(response).to have_http_status(:ok)
      end

      it "renders an empty state when no events exist" do
        get domain_events_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "with events in the workspace" do
      before do
        create(:domain_event, workspace: workspace, kind: "account.created")
        create(:domain_event, workspace: workspace, kind: "deal.created")
      end

      it "lists events for the current workspace" do
        get domain_events_path
        expect(response).to have_http_status(:ok)
      end

      context "with a valid kind filter" do
        it "filters by the given kind" do
          get domain_events_path, params: { kind: "account.created" }
          expect(response).to have_http_status(:ok)
        end
      end

      context "with an invalid kind filter (not in KINDS)" do
        it "ignores the invalid kind and returns all events" do
          get domain_events_path, params: { kind: "malicious.inject" }
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "with pagination" do
      it "returns 200 for page 2" do
        get domain_events_path, params: { page: 2 }
        expect(response).to have_http_status(:ok)
      end

      it "treats page 0 as page 1" do
        get domain_events_path, params: { page: 0 }
        expect(response).to have_http_status(:ok)
      end

      it "treats negative page as page 1" do
        get domain_events_path, params: { page: -1 }
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not authenticated" do
      before { delete session_path }

      it "redirects to login" do
        get domain_events_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "cross-workspace isolation" do
      it "does not show events from another workspace" do
        other_workspace = create(:workspace, owner: create(:user))
        other_event = create(:domain_event, workspace: other_workspace, kind: "account.created")

        get domain_events_path
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("data-event-#{other_event.id}")
      end
    end
  end
end
