class AddRetainerFieldsToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :kind, :integer, null: false, default: 0
    add_column :tickets, :extra_round, :boolean, null: false, default: false
    add_column :tickets, :extra_round_confirmed_at, :datetime
  end
end
