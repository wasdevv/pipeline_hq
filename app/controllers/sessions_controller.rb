# frozen_string_literal: true

class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  # :nocov:
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_session_path, alert: "Tente novamente em alguns minutos." }
  # :nocov:

  def new; end

  def create
    result = Sessions::SignIn.call(
      email_address: params[:email_address],
      password:      params[:password],
      request:       request
    )

    case result.code
    when :signed_in
      start_new_session_for(result.payload)
      redirect_to after_authentication_url
    when :requires_otp
      session[:pending_otp_user_id] = result.payload.id
      redirect_to two_factor_verify_path
    else
      redirect_to new_session_path, alert: "Email ou senha inválidos."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
