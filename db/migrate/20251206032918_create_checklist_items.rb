class CreateChecklistItems < ActiveRecord::Migration[7.1]
  def change
    create_table :checklist_items, force: true do |t|
      t.string :name
      t.boolean :is_checked, default: false, null: false
      t.references :trip, null: false, foreign_key: true

      t.timestamps
    end
  end
end
