class TestCase < ApplicationRecord
  belongs_to :project

  # 邊個寫嘅 test case：SOP 入面三方各寫一份
  enum :source, { client: 0, ae: 1, it: 2 }, prefix: :source

  validates :code, presence: true, uniqueness: { scope: :project_id }
  validates :title, presence: true
end
