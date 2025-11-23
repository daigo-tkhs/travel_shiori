class CreateChecklistItems < ActiveRecord::Migration[7.1]
  def change
    create_table :checklist_items do |t|
      t.references :trip, null: false, foreign_key: true
      t.string :name
      t.boolean :is_checked

      t.timestamps
    end
  end
end
