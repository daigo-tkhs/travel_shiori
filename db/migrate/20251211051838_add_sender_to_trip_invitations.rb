# db/migrate/20251211051838_add_sender_to_trip_invitations.rb
class AddSenderToTripInvitations < ActiveRecord::Migration[7.1]
  def up
    # 1. カラムを追加 (null: true で一旦作成)
    add_reference :trip_invitations, :sender, foreign_key: { to_table: :users }

    # 2. 既存データがある場合のみ、デフォルト値を埋める
    # ▼▼▼ 修正: connection.select_value を使い、nilチェックを行う ▼▼▼
    first_user_id = ActiveRecord::Base.connection.select_value("SELECT id FROM users ORDER BY id ASC LIMIT 1")

    if first_user_id
      # ユーザーが存在する場合のみ更新を実行
      execute("UPDATE trip_invitations SET sender_id = #{first_user_id} WHERE sender_id IS NULL")
    end
    # ▲▲▲ 修正終わり ▲▲▲

    # 3. NOT NULL制約を追加
    change_column_null :trip_invitations, :sender_id, false
  end

  def down
    remove_reference :trip_invitations, :sender
  end
end