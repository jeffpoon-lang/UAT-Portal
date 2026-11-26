class Client < ApplicationRecord
  has_many :projects, dependent: :destroy
  has_many :users, dependent: :nullify
  has_many :tickets, through: :projects
  has_one :retainer_plan, dependent: :destroy
  has_many :monthly_updates, dependent: :destroy

  normalizes :code, with: ->(c) { c.strip.upcase }

  # 有月費維護，或者有 project 已經上線：客戶 portal 先有「月報」
  def has_monthly_reports?
    retainer_plan.present? || projects.where(phase: Ticket::OPEN_PHASES).exists?
  end

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true,
                   format: { with: /\A[A-Z0-9]{2,12}\z/, message: "只可以用 2–12 個英文大楷或數字" }
end
