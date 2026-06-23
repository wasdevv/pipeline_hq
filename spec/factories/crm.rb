# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "Account ##{n}" }
    industry { "SaaS" }
    website  { "https://example.com" }
    notes    { "" }
  end

  factory :stage do
    sequence(:name)     { |n| "Stage ##{n}" }
    sequence(:position) { |n| n }
    color { "#4f46e5" }
  end

  factory :contact do
    association :account
    sequence(:name)  { |n| "Contact ##{n}" }
    sequence(:email) { |n| "contact#{n}@pipelinehq.test" }
    phone { "+55 11 99999-0000" }
    role  { "Decision maker" }
  end

  factory :deal do
    association :account
    association :contact
    association :stage
    sequence(:title) { |n| "Deal ##{n}" }
    amount_cents     { 100_000 }
    currency         { "BRL" }
    expected_close_on { 30.days.from_now.to_date }
    status            { "open" }
  end

  factory :activity do
    association :deal
    kind        { "call" }
    sequence(:subject) { |n| "Activity ##{n}" }
    body        { "Spec body" }
    occurred_at { Time.current }
  end
end
