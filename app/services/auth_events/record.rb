# frozen_string_literal: true

module AuthEvents
  class Record
    def self.call(kind:, user: nil, email_address: nil, request: nil, metadata: {})
      AuthEventJob.perform_later(
        kind:          kind.to_s,
        user_id:       user&.id,
        email_address: email_address || user&.email_address,
        ip_address:    request&.remote_ip,
        user_agent:    request&.user_agent,
        metadata:      metadata
      )
    end
  end
end
