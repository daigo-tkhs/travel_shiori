# spec/factories/checklist_items.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :checklist_item do
    association :trip
    name { "パスポート" } # 具体的なアイテム名
    is_checked { false }
  end
end