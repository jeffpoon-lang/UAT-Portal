class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :contact_email

      t.timestamps
    end
    add_index :clients, :code, unique: true
  end
end
