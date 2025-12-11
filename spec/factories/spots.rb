# frozen_string_literal: true

FactoryBot.define do
  factory :spot do
    association :trip
    name { Faker::Address.street_name }
    estimated_cost { Faker::Number.between(from: 0, to: 10000) }
    travel_time { Faker::Number.between(from: 15, to: 120) }
    position { 1 } # 並び順
  end
end