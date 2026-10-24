class CreateTestCases < ActiveRecord::Migration[8.1]
  def change
    create_table :test_cases do |t|
      t.references :project, null: false, foreign_key: true
      t.string :code, null: false
      t.string :title, null: false
      t.text :steps
      t.text :expected
      t.integer :source, null: false, default: 0

      t.timestamps
    end
    add_index :test_cases, [ :project_id, :code ], unique: true
  end
end
