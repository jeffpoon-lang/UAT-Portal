# 你處理 ticket 嘅每一次記錄：做咗咩、用咗幾耐。客戶睇得到備註。
class TicketLog < ApplicationRecord
  belongs_to :ticket, touch: true
  belongs_to :user

  validates :note, presence: true
  validates :logged_on, presence: true
  validates :minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 24 * 60 }

  scope :in_month, ->(month) { where(logged_on: month.beginning_of_month..month.end_of_month) }
end
