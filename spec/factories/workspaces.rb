# frozen_string_literal: true

FactoryBot.define do
  factory :workspace do
    association :owner, factory: :user
    sequence(:name) { |n| "Workspace #{n}" }
    sequence(:slug) { |n| "workspace-#{n}" }

    trait :with_member do
      transient do
        member { nil }
      end

      after(:create) do |workspace, evaluator|
        user = evaluator.member || create(:user)
        create(:workspace_membership, workspace: workspace, user: user, role: :member)
      end
    end
  end
end
