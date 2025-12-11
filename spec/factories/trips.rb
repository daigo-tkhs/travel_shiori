# frozen_string_literal: true

FactoryBot.define do
  factory :trip do
    # 都市名を使ってタイトルを生成 (例: "横浜市旅行")
    title { "#{Faker::Address.city}旅行" }
    
    # 開始日を今日〜1ヶ月後の間でランダムに設定
    start_date { Faker::Date.forward(days: 30) }
    
    # 終了日を開始日の1〜3日後に設定して、日付の矛盾を防ぐ
    end_date { start_date + Faker::Number.between(from: 1, to: 3).days }
    
    # テーマをランダムな文章で生成
    travel_theme { Faker::Lorem.sentence(word_count: 3) }
    
    # 予算を1万〜30万の間で設定
    total_budget { Faker::Number.between(from: 10_000, to: 300_000) }
    
    # 関連付け: 自動的に所有者(User)も生成する
    association :owner, factory: :user
  end
end