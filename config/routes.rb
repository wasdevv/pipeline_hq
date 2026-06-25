Rails.application.routes.draw do
  root "home#show"

  # Auth público
  resource  :session, only: %i[new create destroy]
  resource  :registration, only: %i[new create], path: "sign_up"
  resources :confirmations, only: %i[new create show], param: :token
  resources :passwords, only: %i[new create edit update], param: :token

  # 2FA durante login (público)
  get  "two_factor/verify",  to: "two_factors#verify",  as: :two_factor_verify
  post "two_factor/verify",  to: "two_factors#consume"

  # 2FA gerenciamento (autenticado + sudo)
  resource :two_factor, only: %i[show destroy] do
    get  :enroll
    post :enroll, action: :confirm
    post :backup_codes, action: :regenerate_backup_codes
  end

  # Sessões ativas (autenticado)
  scope :sessions_management do
    get    "/", to: "sessions_management#index",       as: :sessions_management_index
    delete "/", to: "sessions_management#destroy_all", as: :sessions_management_destroy_all
    delete ":id", to: "sessions_management#destroy",   as: :sessions_management_destroy
  end

  # Sudo
  resource :sudo, only: %i[new create], controller: "sudo_sessions"

  # Workspaces
  resources :workspaces, only: %i[new create show edit update] do
    resources :memberships, only: %i[index], controller: "workspace_memberships"
    post :switch, on: :member, to: "workspace_switches#create"
  end

  # CRM resources (autenticadas)
  resources :activities
  resources :deals
  resources :stages
  resources :contacts
  resources :accounts

  get "up" => "rails/health#show", as: :rails_health_check
end
