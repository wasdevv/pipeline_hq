# frozen_string_literal: true

module SudoRequired
  extend ActiveSupport::Concern

  class_methods do
    def require_sudo(**options)
      before_action :require_sudo!, **options
    end
  end

  private

  def require_sudo!
    return if current_session&.sudo?

    session[:sudo_return_to] = request.url if request.get? || request.head?
    redirect_to new_sudo_path, alert: "Confirme sua senha para continuar."
  end
end
