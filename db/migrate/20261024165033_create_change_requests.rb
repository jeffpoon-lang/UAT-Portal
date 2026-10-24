class CreateChangeRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :change_requests do |t|
      t.references :project, null: false, foreign_key: true
      t.string :doc_number, null: false
      t.text :description, null: false
      t.integer :extra_rounds, null: false, default: 1
      t.integer :quote_hkd
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :change_requests, :doc_number, unique: true
  end
end
