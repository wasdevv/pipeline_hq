# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Test stack configuration" do
  it "boots in the test environment" do
    expect(Rails.env).to eq("test")
  end

  it "defaults the locale to pt-BR" do
    expect(I18n.default_locale).to eq(:"pt-BR")
    expect(I18n.available_locales).to include(:"pt-BR")
  end

  it "builds a valid :user factory" do
    user = build(:user)
    expect(user).to be_valid
    expect(user.email_address).to match(/@pipelinehq\.test\z/)
  end

  it "blocks external HTTP calls via WebMock" do
    expect { Net::HTTP.get(URI("https://example.com")) }
      .to raise_error(WebMock::NetConnectNotAllowedError)
  end
end
