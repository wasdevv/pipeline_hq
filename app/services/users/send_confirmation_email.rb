# frozen_string_literal: true

module Users
  class SendConfirmationEmail
    def self.call(user)
      token = user.generate_token_for(:email_confirmation)
      ConfirmationsMailer.confirm(user, token).deliver_later
      user.update_column(:confirmation_sent_at, Time.current)
      AuthEvents::Record.call(kind: :email_confirmation_sent, user: user)
    end
  end
end
