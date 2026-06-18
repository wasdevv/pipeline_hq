# frozen_string_literal: true

class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[edit update]
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_password_path, alert: "Tente novamente em alguns minutos." }

  def new; end

  def create
    user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)
    if user
      PasswordsMailer.reset(user).deliver_later
      AuthEvents::Record.call(kind: :password_reset_requested, user: user, request: request)
    end

    redirect_to new_session_path, notice: "Se a conta existir, enviamos as instruções por email."
  end

  def edit; end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      Users::ResetFailedAttempts.call(user: @user)
      AuthEvents::Record.call(kind: :password_reset_completed, user: @user, request: request)
      redirect_to new_session_path, notice: "Senha atualizada. Faça login."
    else
      redirect_to edit_password_path(params[:token]), alert: "As senhas não coincidem ou são inválidas."
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: "Link de redefinição inválido ou expirado."
  end
end
