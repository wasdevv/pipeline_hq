# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasswordStrengthValidator do
  def build_user(password)
    User.new(
      name:                  "Maria",
      email_address:         "x@pipelinehq.test",
      password:              password,
      password_confirmation: password
    )
  end

  it "accepts a strong password (length + complexity)" do
    user = build_user("StrongPass!2026")
    user.valid?
    expect(user.errors[:password]).to be_empty
  end

  it "rejects passwords shorter than MIN_LENGTH" do
    user = build_user("Short!1")
    user.valid?
    expect(user.errors[:password]).to include(match(/curt|short/i))
  end

  it "rejects passwords with fewer than 3 character classes" do
    user = build_user("alllowercase")
    user.valid?
    expect(user.errors[:password]).to be_present
  end

  it "accepts a password missing one character class as long as 3 are present" do
    user = build_user("LongPasswordNoDigits!")
    user.valid?
    expect(user.errors[:password]).to be_empty
  end

  it "skips validation when value is blank (allow_nil semantics)" do
    record = Struct.new(:password) do
      include ActiveModel::Validations
      validates :password, password_strength: true, allow_nil: true
    end.new(nil)

    expect(record.valid?).to be(true)
  end

  it "exposes MIN_LENGTH as a frozen constant" do
    expect(PasswordStrengthValidator::MIN_LENGTH).to eq(12)
  end
end
