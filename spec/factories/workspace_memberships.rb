# frozen_string_literal: true

FactoryBot.define do
  factory :workspace_membership do
    association :workspace
    association :user

    trait :owner_role do
      role { :owner }
    end

    trait :admin_role do
      role { :admin }
    end

    trait :member_role do
      role { :member }
    end

    trait :viewer_role do
      role { :viewer }
    end
  end
end
