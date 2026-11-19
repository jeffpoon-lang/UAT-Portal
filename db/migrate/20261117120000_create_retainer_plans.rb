class CreateRetainerPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :retainer_plans do |t|
      t.references :client, null: false, foreign_key: true, index: { unique: true }
      t.integer :monthly_fee_hkd, null: false
      t.integer :included_rounds, null: false, default: 3
      t.integer :extra_round_hkd, null: false, default: 500
      t.date :starts_on, null: false
      t.integer :notice_days, null: false, default: 30
      t.string :quote_ref
      t.date :notice_given_on
      t.integer :notice_given_by
      t.timestamps
    end
  end
end
