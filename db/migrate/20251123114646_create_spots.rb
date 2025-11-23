class CreateSpots < ActiveRecord::Migration[7.1]
  def change
    create_table :spots do |t|
      t.references :trip, null: false, foreign_key: true
      t.integer :day_number
      t.string :name
      t.decimal :estimated_cost
      t.integer :duration
      t.string :booking_url

      t.timestamps
    end
  end
end
