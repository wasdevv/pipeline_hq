# frozen_string_literal: true

require "concurrent"

module Presence
  class Tracker
    @workspaces = Concurrent::Map.new
    @counts     = Concurrent::Map.new

    class << self
      def add(workspace_id, user_id)
        key = key_for(workspace_id, user_id)
        count = (@counts[key] || 0) + 1
        @counts[key] = count
        members_for(workspace_id).add(user_id)
        count == 1
      end

      def remove(workspace_id, user_id)
        key = key_for(workspace_id, user_id)
        current = @counts[key].to_i - 1
        if current <= 0
          @counts.delete(key)
          members_for(workspace_id).delete(user_id)
          return true
        end

        @counts[key] = current
        false
      end

      def online_ids(workspace_id)
        members_for(workspace_id).to_a
      end

      def online?(workspace_id, user_id)
        members_for(workspace_id).include?(user_id)
      end

      def reset!
        @workspaces.clear
        @counts.clear
      end

      private

      def members_for(workspace_id)
        @workspaces.compute_if_absent(workspace_id) { Concurrent::Set.new }
      end

      def key_for(workspace_id, user_id)
        "#{workspace_id}:#{user_id}"
      end
    end
  end
end
