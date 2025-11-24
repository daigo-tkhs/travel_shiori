# app/models/trip_user.rb

class TripUser < ApplicationRecord
  belongs_to :user
  belongs_to :trip
  
  # 権限レベルの定義 (db_schema.mdに従いenumを使用)
  enum permission_level: { viewer: 1, editor: 2, owner: 3 }
end