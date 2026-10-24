class CreateSignOffs < ActiveRecord::Migration[8.1]
  def change
    create_table :sign_offs do |t|
      t.references :project, null: false, foreign_key: true
      t.references :uat_round, null: false, foreign_key: true, index: { unique: true }
      t.references :signed_by, null: false, foreign_key: { to_table: :users }
      t.string :signer_name, null: false
      t.datetime :signed_at, null: false
      t.string :doc_number, null: false
      t.text :payload_json, null: false
      t.string :digest, null: false
      t.string :prev_digest, null: false

      t.timestamps
    end
    add_index :sign_offs, :doc_number, unique: true
    add_index :sign_offs, :digest, unique: true
  end
end
