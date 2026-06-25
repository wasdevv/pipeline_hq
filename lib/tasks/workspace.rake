# frozen_string_literal: true

namespace :workspace do
  desc "Backfill workspace_id on all CRM tables. Idempotent — safe to re-run."
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

      [ Account, Contact, Stage, Deal, Activity ].each do |klass|
        table = klass.quoted_table_name
        klass.unscoped.where(workspace_id: nil).find_each(batch_size: 1000) do |record|
          record.update_columns(workspace_id: workspace.id)
        end
      end
    end

    puts "workspace:backfill done."
  end
end
