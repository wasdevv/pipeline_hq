# frozen_string_literal: true

class ConfirmationsMailer < ApplicationMailer
  def confirm(user, token)
    @user  = user
    @token = token
    mail to: user.email_address, subject: "Confirme seu email — PipelineHQ"
  end
end
