# spec/factories/trip_users.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :trip_user do
    association :trip
    association :user
    
    # 権限 (モデルの実装に合わせて :viewer, :editor, :owner など)
    # ここでは一般的な 'viewer' をデフォルトにします
    permission_level { 'viewer' }
  end
end