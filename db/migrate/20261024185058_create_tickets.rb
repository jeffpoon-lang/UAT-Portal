class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.references :project, null: false, foreign_key: true
      t.references :opened_by, null: false, foreign_key: { to_table: :users }
      t.string :doc_number, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.integer :priority, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.datetime :resolved_at

      t.timestamps
    end
    add_index :tickets, :doc_number, unique: true
    add_index :tickets, :status
  end
end
