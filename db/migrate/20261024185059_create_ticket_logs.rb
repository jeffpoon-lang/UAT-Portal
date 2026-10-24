class CreateTicketLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_logs do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :logged_on, null: false
      t.integer :minutes, null: false, default: 0
      t.text :note, null: false

      t.timestamps
    end
    add_index :ticket_logs, :logged_on
  end
end
