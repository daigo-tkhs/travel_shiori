class CreateTripInvitations < ActiveRecord::Migration[7.1]
  def change
    create_table :trip_invitations do |t|
      t.references :trip, null: false, foreign_key: true
      t.string :email, null: false
      t.integer :role, null: false, default: 0
      t.string :token, null: false
      t.datetime :accepted_at
      t.datetime :expires_at

      t.timestamps
    end
    # トークンで検索するための一意制約
    add_index :trip_invitations, :token, unique: true
  end
end