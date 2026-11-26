# UAT 喺系統以外簽咗（紙本／PDF）嘅聲明。只係記錄，唔入 sign_offs 嘅 hash chain。
class CreateExternalSignOffs < ActiveRecord::Migration[8.1]
  def change
    create_table :external_sign_offs do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.string :scope
      t.string :title, null: false
      t.text :statement
      t.string :signer_name, null: false
      t.date :signed_on, null: false
      t.string :countersigned_by
      t.boolean :final, null: false, default: false
      t.text :note
      t.timestamps
    end
  end
end
