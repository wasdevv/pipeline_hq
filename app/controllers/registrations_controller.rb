# frozen_string_literal: true

class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_registration_path, alert: "Tente novamente em alguns minutos." }

  def new
    @user = User.new
  end

  def create
    if params[:nickname].present?
      AuthEvents::Record.call(kind: :honeypot_triggered, email_address: registration_params[:email_address], request: request)
      return redirect_to new_confirmation_path, notice: "Quase pronto. Verifique seu email."
    end

    result = Users::Register.call(params: registration_params, request: request)

    if result.success?
      redirect_to new_confirmation_path, notice: "Conta criada. Verifique seu email para confirmar."
    else
      @user = result.payload || User.new(registration_params.except(:password))
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.expect(user: %i[name email_address password password_confirmation])
  end
end
