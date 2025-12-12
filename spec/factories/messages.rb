# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    association :trip
    association :user
    
    prompt { "東京のおすすめスポットを教えてください" }
    response { "東京タワーと浅草寺がおすすめです。" } # AIの回答（任意）
  end
end