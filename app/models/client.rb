class Client < ApplicationRecord
  has_many :projects, dependent: :destroy
  has_many :users, dependent: :nullify
  has_many :tickets, through: :projects

  normalizes :code, with: ->(c) { c.strip.upcase }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true,
                   format: { with: /\A[A-Z0-9]{2,12}\z/, message: "只可以用 2–12 個英文大楷或數字" }
end
