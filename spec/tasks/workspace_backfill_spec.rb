# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "workspace:backfill rake task", type: :task do
  subject(:run_task) { Rake::Task["workspace:backfill"].execute }

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["workspace:backfill"].reenable
  end

  describe "happy path — single user without workspace" do
    let!(:user) { create(:user) }

    before { user.update_columns(current_workspace_id: nil) }

    it "creates a workspace for the user" do
      expect { run_task }.to change(Workspace, :count).by(1)
    end

    it "creates an owner membership" do
      expect { run_task }.to change(WorkspaceMembership, :count).by(1)
      expect(WorkspaceMembership.last.role).to eq("owner")
    end

    it "sets current_workspace_id on the user" do
      run_task
      expect(user.reload.current_workspace_id).not_to be_nil
    end

    it "slugs the workspace as legacy-<user_id>" do
      run_task
      slug = Workspace.last.slug
      expect(slug).to eq("legacy-#{user.id}")
    end
  end

  describe "idempotency" do
    let!(:user) { create(:user) }

    before { user.update_columns(current_workspace_id: nil) }

    it "does not create duplicate workspaces on second run" do
      run_task
      Rake::Task["workspace:backfill"].reenable
      expect { run_task }.not_to change(Workspace, :count)
    end

    it "does not create duplicate memberships on second run" do
      run_task
      Rake::Task["workspace:backfill"].reenable
      expect { run_task }.not_to change(WorkspaceMembership, :count)
    end

    it "does not overwrite current_workspace_id when already set" do
      run_task
      workspace_id_after_first_run = user.reload.current_workspace_id

      Rake::Task["workspace:backfill"].reenable
      run_task

      expect(user.reload.current_workspace_id).to eq(workspace_id_after_first_run)
    end
  end

  describe "multiple users" do
    let!(:user_a) { create(:user) }
    let!(:user_b) { create(:user) }

    before do
      user_a.update_columns(current_workspace_id: nil)
      user_b.update_columns(current_workspace_id: nil)
    end

    it "creates one workspace per user" do
      expect { run_task }.to change(Workspace, :count).by(2)
    end

    it "creates one membership per user" do
      expect { run_task }.to change(WorkspaceMembership, :count).by(2)
    end

    it "each user gets their own distinct workspace" do
      run_task
      expect(user_a.reload.current_workspace_id).not_to eq(user_b.reload.current_workspace_id)
    end
  end

  describe "user already backfilled (legacy workspace exists)" do
    let!(:user) { create(:user) }

    before do
      user.update_columns(current_workspace_id: nil)
      run_task
      Rake::Task["workspace:backfill"].reenable
    end

    it "does not create a duplicate legacy workspace" do
      expect { run_task }.not_to change(Workspace, :count)
    end

    it "does not create a duplicate owner membership" do
      expect { run_task }.not_to change(WorkspaceMembership, :count)
    end
  end
end
