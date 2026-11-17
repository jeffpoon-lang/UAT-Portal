class CreateMonthlyUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :monthly_updates do |t|
      t.references :client, null: false, foreign_key: true
      t.date :month, null: false
      t.text :done_summary
      t.text :next_steps
      t.timestamps
    end
    add_index :monthly_updates, [ :client_id, :month ], unique: true
  end
end
