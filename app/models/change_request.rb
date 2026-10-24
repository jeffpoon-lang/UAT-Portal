# 超出合約 round 數或者改需求：開 CR，客同意（簽咗）之後你喺度批核
class ChangeRequest < ApplicationRecord
  belongs_to :project

  enum :status, { pending: 0, approved: 1, rejected: 2 }, prefix: :status

  before_validation :assign_doc_number, on: :create

  validates :doc_number, presence: true, uniqueness: true
  validates :description, presence: true
  validates :extra_rounds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quote_hkd, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  private
    def assign_doc_number
      return if doc_number.present? || project.nil?

      code = project.client.code
      n = ChangeRequest.joins(:project).where(projects: { client_id: project.client_id }).count + 1
      self.doc_number = format("CR-%s-%03d", code, n)
    end
end
