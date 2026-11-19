class CreateHandoverItems < ActiveRecord::Migration[8.1]
  def change
    create_table :handover_items do |t|
      t.references :retainer_plan, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.string :title, null: false
      t.integer :side, null: false, default: 0
      t.datetime :done_at
      t.references :done_by, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
