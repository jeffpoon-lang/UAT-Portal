# 交付咗嘅系統有啲咩網址、帳戶喺邊個名下：客戶喺 portal 長期睇到
class CreateSystemLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :system_links do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :kind, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.string :label, null: false
      t.string :url
      t.string :account_owner
      t.text :note
      t.timestamps
    end

    add_column :projects, :support_notes, :text
  end
end
