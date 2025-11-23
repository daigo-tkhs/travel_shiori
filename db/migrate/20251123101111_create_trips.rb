class CreateTrips < ActiveRecord::Migration[7.1]
  def change
    create_table :trips do |t|
      t.integer :owner_id
      t.string :title
      t.date :start_date
      t.integer :total_budget
      t.string :travel_theme
      t.text :context

      t.timestamps
    end
  end
end
