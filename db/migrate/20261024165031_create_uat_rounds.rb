class CreateUatRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :uat_rounds do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :number, null: false
      t.integer :status, null: false, default: 0
      t.datetime :opened_at, null: false
      t.datetime :closed_at

      t.timestamps
    end
    add_index :uat_rounds, [ :project_id, :number ], unique: true
  end
end
