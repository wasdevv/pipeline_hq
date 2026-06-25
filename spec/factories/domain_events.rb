# frozen_string_literal: true

FactoryBot.define do
  factory :domain_event do
    association :workspace
    kind     { "account.created" }
    metadata { { "source" => "spec" } }
  end
end
