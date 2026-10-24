class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :client, optional: true

  enum :role, { admin: 0, client: 1 }, prefix: :role

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :client, presence: true, if: :role_client?
end
