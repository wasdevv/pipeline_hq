# frozen_string_literal: true

module Sessions
  class StartSudo
    def self.call(session:, password:, request: nil)
      user = session.user

      unless User.authenticate_by(email_address: user.email_address, password: password)
        return Result.failure(:invalid_password)
      end

      session.update!(sudo_until: Session::SUDO_DURATION.from_now)
      AuthEvents::Record.call(kind: :sudo_started, user: user, request: request)
      Result.success(:sudo_started, session)
    end
  end
end
