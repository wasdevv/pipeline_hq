# frozen_string_literal: true

module Sessions
  class TouchActivity
    def self.call(session)
      return if session.nil?
      return if session.last_active_at && session.last_active_at > Session::TOUCH_THROTTLE.ago

      session.update_columns(last_active_at: Time.current)
    end
  end
end
