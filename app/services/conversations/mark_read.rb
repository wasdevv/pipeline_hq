# frozen_string_literal: true

module Conversations
  class MarkRead
    def self.call(participant:, at: Time.current)
      return Result.failure(:invalid) if participant.blank?

      participant.update!(last_read_at: at)
      Result.success(:marked, participant)
    end
  end
end
