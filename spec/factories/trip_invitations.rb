# frozen_string_literal: true

FactoryBot.define do
  factory :trip_invitation do
    email { Faker::Internet.email }
    role { %w[viewer editor].sample } # viewer か editor をランダム選択
    
    # モデルのバリデーションに合わせて一意なトークンを生成
    token { SecureRandom.urlsafe_base64 }
    
    expires_at { 1.week.from_now }
    
    # 関連付け
    association :trip
    association :sender, factory: :user
  end
end