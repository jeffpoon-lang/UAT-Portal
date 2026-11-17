# 每月進度更新：本月做咗咩、下個月建議。印喺月尾報告度寄畀客
class MonthlyUpdate < ApplicationRecord
  belongs_to :client

  before_validation { self.month = month&.beginning_of_month }

  validates :month, presence: true, uniqueness: { scope: :client_id }

  def self.for(client, month) = find_by(client: client, month: month.beginning_of_month)
end
