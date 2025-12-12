# spec/factories/favorites.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :favorite do
    association :trip
    association :user
  end
end