# 終止合約時嘅交接清單；客戶只可以剔客戶嗰份，admin 兩邊都剔得
class HandoverItem < ApplicationRecord
  belongs_to :retainer_plan
  belongs_to :done_by, class_name: "User", optional: true

  enum :side, { client: 0, provider: 1 }, prefix: :side

  SIDE_LABELS = { "client" => "客戶負責", "provider" => "服務提供者負責" }.freeze

  validates :title, presence: true

  def done? = done_at.present?
  def side_label = SIDE_LABELS.fetch(side)

  def editable_by?(user)
    user.role_admin? || (side_client? && user.client_id == retainer_plan.client_id)
  end

  def mark!(done:, user:)
    update!(done_at: done ? (done_at || Time.current) : nil, done_by: done ? (done_by || user) : nil)
  end
end
