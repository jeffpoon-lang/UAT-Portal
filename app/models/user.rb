class User < ApplicationRecord
  MIN_PASSWORD_LENGTH = 8

  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :client, optional: true

  enum :role, { admin: 0, client: 1 }, prefix: :role

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :client, presence: true, if: :role_client?
  validates :password, length: { minimum: MIN_PASSWORD_LENGTH }, allow_nil: true

  # 開帳戶或者重設時自動產生嘅密碼，例如 4fKq-9XwB-m2Tz（約 70 bit）
  def self.generate_password = SecureRandom.base58(12).scan(/.{4}/).join("-")
end
