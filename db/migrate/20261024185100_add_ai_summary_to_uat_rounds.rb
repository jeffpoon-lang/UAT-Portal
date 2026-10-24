class AddAiSummaryToUatRounds < ActiveRecord::Migration[8.1]
  def change
    add_column :uat_rounds, :ai_summary, :jsonb
    add_column :uat_rounds, :ai_summarised_at, :datetime
  end
end
