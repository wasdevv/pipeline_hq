# frozen_string_literal: true

namespace :workspace do
  desc "Backfill workspace + owner membership + current_workspace_id for each user. Idempotent — safe to re-run."
  task backfill: :environment do
    User.find_each(batch_size: 500) do |user|
      workspace = Workspace.find_or_create_by!(slug: "legacy-#{user.id}") do |w|
        w.name     = "#{user.name}'s Workspace"
        w.owner_id = user.id
      end

      WorkspaceMembership.find_or_create_by!(workspace: workspace, user: user) do |m|
        m.role = :owner
      end

      user.update_columns(current_workspace_id: workspace.id) if user.current_workspace_id.nil?
    end

    puts "workspace:backfill done."
  end
end
