# frozen_string_literal: true

class TwoFactorsController < ApplicationController
  include SudoRequired

  require_sudo except: %i[verify consume]
  allow_unauthenticated_access only: %i[verify consume]
  rate_limit to: 5, within: 5.minutes, only: :consume,
             with: -> { redirect_to new_session_path, alert: "Muitas tentativas. Tente novamente em breve." }

  def show
    @enabled    = current_user.otp_enabled?
    @backup_count = current_user.otp_backup_codes.size
  end

  def enroll
    result = TwoFactor::Enroll.call(user: current_user)
    session[:pending_otp_secret] = result.payload[:secret]
    @qr_svg = result.payload[:qr_svg]
    @secret = result.payload[:secret]
  end

  def confirm
    secret = session[:pending_otp_secret]
    return redirect_to enroll_two_factor_path, alert: "Inicie a configuração novamente." if secret.blank?

    result = TwoFactor::Confirm.call(user: current_user, secret: secret, code: params[:code], request: request)

    if result.success?
      session.delete(:pending_otp_secret)
      @backup_codes = result.payload
      render :backup_codes
    else
      redirect_to enroll_two_factor_path, alert: "Código inválido. Tente novamente."
    end
  end

  def regenerate_backup_codes
    result = TwoFactor::RegenerateBackupCodes.call(user: current_user, request: request)
    @backup_codes = result.payload
    render :backup_codes
  end

  def destroy
    TwoFactor::Disable.call(user: current_user, request: request)
    redirect_to two_factor_path, notice: "2FA desativado."
  end

  def verify
    @user = pending_otp_user
    redirect_to new_session_path, alert: "Sessão expirada. Faça login novamente." if @user.nil?
  end

  def consume
    user = pending_otp_user
    return redirect_to new_session_path, alert: "Sessão expirada." if user.nil?

    result = TwoFactor::Verify.call(user: user, code: params[:code], request: request)

    if result.success?
      Users::ResetFailedAttempts.call(user: user)
      session.delete(:pending_otp_user_id)
      start_new_session_for(user)
      redirect_to after_authentication_url
    else
      redirect_to two_factor_verify_path, alert: "Código inválido."
    end
  end

  private

  def pending_otp_user
    id = session[:pending_otp_user_id]
    User.find_by(id: id) if id
  end
end
