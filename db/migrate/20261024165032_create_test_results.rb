class CreateTestResults < ActiveRecord::Migration[8.1]
  def change
    create_table :test_results do |t|
      t.references :uat_round, null: false, foreign_key: true
      t.references :test_case, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.text :comment

      t.timestamps
    end
    add_index :test_results, [ :uat_round_id, :test_case_id ], unique: true
  end
end
