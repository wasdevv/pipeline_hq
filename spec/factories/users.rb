# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name          { Faker::Name.name }
    sequence(:email_address) { |n| "user#{n}@pipelinehq.test" }
    password              { "TestUser!2026PipelineHQ" }
    password_confirmation { "TestUser!2026PipelineHQ" }
    confirmed_at          { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :locked do
      locked_at        { 1.minute.ago }
      failed_attempts  { User::LOCK_THRESHOLD }
    end

    trait :with_2fa do
      otp_secret      { ROTP::Base32.random }
      otp_enabled_at  { Time.current }
    end
  end
end
