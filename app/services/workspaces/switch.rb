# frozen_string_literal: true

module Workspaces
  class Switch
    def self.call(...) = new(...).call

    def initialize(user:, workspace:)
      @user = user
      @workspace = workspace
    end

    def call
      return Result.failure(:not_found) if @workspace.nil?

      unless @user.workspace_memberships.exists?(workspace_id: @workspace.id)
        return Result.failure(:not_member)
      end

      @user.update!(current_workspace_id: @workspace.id)
      Result.success(:switched, @workspace)
    end
  end
end
