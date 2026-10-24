class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.references :client, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :phase, null: false, default: 0
      t.integer :max_uat_rounds, null: false, default: 3
      t.date :maintenance_start_on

      t.timestamps
    end
  end
end
