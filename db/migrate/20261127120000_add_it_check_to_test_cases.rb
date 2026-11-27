# IT 交 UAT 之前自己試過嘅結果：同客戶嘅驗收結果（test_results）分開記，
# 客戶喺 portal 見到邊幾條 IT 已經試過通過。
class AddItCheckToTestCases < ActiveRecord::Migration[8.1]
  def change
    add_column :test_cases, :it_status, :integer, null: false, default: 0
    add_column :test_cases, :it_note, :text
    add_column :test_cases, :it_tested_on, :date
  end
end
