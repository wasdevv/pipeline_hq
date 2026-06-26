# frozen_string_literal: true

module Workspaces
  class Create
    MAX_SLUG_ATTEMPTS = 5

    def self.call(...) = new(...).call

    def initialize(user:, name:)
      @user = user
      @name = name
    end

    def call
      return Result.failure(:user_blank) if @user.blank?

      workspace = nil

      ActiveRecord::Base.transaction do
        workspace = build_workspace
        return Result.failure(:invalid, workspace.errors, workspace) unless workspace.save

        WorkspaceMembership.create!(workspace: workspace, user: @user, role: :owner)
        @user.update!(current_workspace_id: workspace.id)
      end

      DomainEvents::Record.call(
        kind:     "workspace.created",
        workspace: workspace,
        actor:    @user,
        metadata: { slug: workspace.slug, name: workspace.name }
      )

      Result.success(:created, workspace)
    rescue ActiveRecord::RecordNotUnique
      Result.failure(:slug_taken)
    end

    private

    def build_workspace
      slug = generate_unique_slug(@name)
      Workspace.new(name: @name, slug: slug, owner: @user)
    end

    def generate_unique_slug(name)
      base = name.parameterize
      base = "workspace" if base.blank?

      return base unless Workspace.exists?(slug: base)

      (2..MAX_SLUG_ATTEMPTS).each do |n|
        candidate = "#{base}-#{n}"
        return candidate unless Workspace.exists?(slug: candidate)
      end

      "#{base}-#{SecureRandom.hex(3)}"
    end
  end
end
