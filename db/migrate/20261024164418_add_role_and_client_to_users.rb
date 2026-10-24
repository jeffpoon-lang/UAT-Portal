class AddRoleAndClientToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :integer, null: false, default: 1
    add_reference :users, :client, null: true, foreign_key: true
  end
end
