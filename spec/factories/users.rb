# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name          { Faker::Name.name }
    sequence(:email_address) { |n| "user#{n}@pipelinehq.test" }
    password              { "TestUser!2026PipelineHQ" }
    password_confirmation { "TestUser!2026PipelineHQ" }
    confirmed_at          { Time.current }

    after(:create) do |user|
      workspace = create(:workspace, owner: user)
      create(:workspace_membership, workspace: workspace, user: user, role: :owner)
      user.update_columns(current_workspace_id: workspace.id)
      user.reload
    end

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

    trait :with_backup_codes do
      transient do
        plain_codes { Array.new(User::BACKUP_CODE_COUNT) { SecureRandom.hex(4) } }
      end

      otp_backup_codes { plain_codes.map { |c| BCrypt::Password.create(c).to_s } }
    end
  end
end
