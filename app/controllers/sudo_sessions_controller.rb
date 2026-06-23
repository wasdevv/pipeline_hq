# frozen_string_literal: true

class SudoSessionsController < ApplicationController
  # :nocov:
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_sudo_path, alert: "Tente novamente em alguns minutos." }
  # :nocov:

  def new; end

  def create
    result = Sessions::StartSudo.call(session: current_session, password: params[:password], request: request)

    if result.success?
      redirect_to(session.delete(:sudo_return_to) || root_url, notice: "Modo seguro ativo por 15 minutos.")
    else
      redirect_to new_sudo_path, alert: "Senha incorreta."
    end
  end
end
