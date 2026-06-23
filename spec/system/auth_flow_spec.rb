# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth flow", type: :system do
  include ActiveJob::TestHelper

  let(:name)     { "Maria Souza" }
  let(:email)    { "maria.systemspec@pipelinehq.test" }
  let(:password) { AuthenticationHelpers::TEST_PASSWORD }

  it "walks signup -> email confirmation -> login -> 2FA enroll -> logout -> login with 2FA -> verify" do
    visit new_registration_path

    fill_in "Nome", with: name
    fill_in "Email", with: email
    fill_in "Senha (mín. 12 caracteres)", with: password
    fill_in "Confirme a senha", with: password

    expect {
      perform_enqueued_jobs { click_button "Criar conta" }
    }.to change(User, :count).by(1)
       .and change { ActionMailer::Base.deliveries.size }.by(1)

    expect(page).to have_current_path(new_confirmation_path)
    expect(page).to have_content("Conta criada")

    user  = User.find_by!(email_address: email)
    token = user.generate_token_for(:email_confirmation)

    visit "/confirmations/#{token}"

    expect(page).to have_current_path(new_session_path)
    expect(page).to have_content("Email confirmado")
    expect(user.reload.confirmed_at).to be_present

    fill_in "Email", with: email
    fill_in "Senha", with: password
    click_button "Sign in"

    expect(page).to have_current_path(root_path)

    visit enroll_two_factor_path

    expect(page).to have_current_path(new_sudo_path)
    expect(page).to have_content("Modo seguro")

    fill_in "Senha", with: password
    click_button "Confirmar"

    expect(page).to have_current_path(enroll_two_factor_path)
    expect(page).to have_content("Ativar autenticação em duas etapas")

    secret = page.find("code").text.strip
    totp   = ROTP::TOTP.new(secret)

    fill_in "Código do app", with: totp.now
    perform_enqueued_jobs { click_button "Confirmar e ativar" }

    expect(page).to have_content("Backup codes")
    expect(user.reload.otp_enabled_at).to be_present
    expect(user.otp_backup_codes.size).to eq(User::BACKUP_CODE_COUNT)

    page.driver.submit :delete, session_path, {}

    expect(page).to have_current_path(new_session_path)

    fill_in "Email", with: email
    fill_in "Senha", with: password
    click_button "Sign in"

    expect(page).to have_current_path(two_factor_verify_path)
    expect(page).to have_content("Código de verificação")

    fill_in "Código", with: totp.now
    perform_enqueued_jobs { click_button "Verificar" }

    expect(page).to have_current_path(root_path)
  end
end
