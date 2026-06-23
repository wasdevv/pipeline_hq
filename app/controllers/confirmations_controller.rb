# frozen_string_literal: true

class ConfirmationsController < ApplicationController
  allow_unauthenticated_access
  # :nocov:
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_confirmation_path, alert: "Tente novamente em alguns minutos." }
  # :nocov:

  def new; end

  def create
    user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)
    Users::SendConfirmationEmail.call(user) if user && !user.confirmed?

    redirect_to new_session_path, notice: "Se a conta existir, enviamos um novo link de confirmação."
  end

  def show
    result = Users::Confirm.call(token: params[:token], request: request)

    case result.code
    when :confirmed
      redirect_to new_session_path, notice: "Email confirmado. Faça login."
    when :already_confirmed
      redirect_to new_session_path, notice: "Email já confirmado anteriormente."
    else
      redirect_to new_confirmation_path, alert: "Link inválido ou expirado."
    end
  end
end
