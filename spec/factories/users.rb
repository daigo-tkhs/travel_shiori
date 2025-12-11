# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    # 一意なメールアドレスを生成
    email { Faker::Internet.unique.email }
    
    # ランダムな名前 (例: "Taro Yamada")
    nickname { Faker::Name.name }
    
    # パスワードはテストでの利便性のため固定値推奨ですが、十分な長さがあればOK
    password { 'password' }
    password_confirmation { 'password' }
  end
end