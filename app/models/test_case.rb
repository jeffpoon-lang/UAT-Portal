class TestCase < ApplicationRecord
  belongs_to :project

  # 邊個寫嘅 test case：SOP 入面三方各寫一份
  enum :source, { client: 0, ae: 1, it: 2 }, prefix: :source

  # IT 交 UAT 之前自己試過嘅結果。唔係客戶嘅驗收結果（嗰啲喺 TestResult，跟 round 行）。
  enum :it_status, { untested: 0, pass: 1, fail: 2 }, prefix: :it
  IT_STATUS_LABELS = { "untested" => "IT 未測", "pass" => "IT 已測通過", "fail" => "IT 測試未過" }.freeze

  before_validation :settle_it_tested_on

  validates :code, presence: true, uniqueness: { scope: :project_id }
  validates :title, presence: true
  validate :it_tested_on_not_in_future

  scope :it_checked, -> { where.not(it_status: :untested) }

  def it_status_label = IT_STATUS_LABELS.fetch(it_status)
  def it_checked? = !it_untested?

  private
    # 有結果但冇填日期就當今日；改返做未測就清走日期，免得留低一個冇意思嘅日子
    def settle_it_tested_on
      if it_untested?
        self.it_tested_on = nil
      elsif it_tested_on.blank?
        self.it_tested_on = Date.current
      end
    end

    def it_tested_on_not_in_future
      errors.add(:it_tested_on, "唔可以係未來日子") if it_tested_on && it_tested_on > Date.current
    end
end
