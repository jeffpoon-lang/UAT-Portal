class UatRound < ApplicationRecord
  class NotAllowed < StandardError; end

  belongs_to :project
  has_many :test_results, -> { joins(:test_case).order("test_cases.code") }, dependent: :destroy
  has_one :sign_off, dependent: :restrict_with_error

  # open = 客測緊；changes_requested = 客交咗有問題要改；signed_off = 已簽，鎖死
  enum :status, { open: 0, changes_requested: 1, signed_off: 2 }, prefix: :status

  validates :number, presence: true, uniqueness: { scope: :project_id }

  def all_answered? = test_results.none?(&:status_pending?)
  def all_passed? = test_results.any? && test_results.all?(&:status_pass?)
  def failing_results = test_results.reject(&:status_pass?)

  def counts
    TestResult.statuses.keys.index_with { |s| test_results.count { |r| r.status == s } }
  end

  # 客交結果但有問題：關 round，等你改完開下一個
  def request_changes!
    raise NotAllowed, "呢個 round 已經關咗" unless status_open?
    raise NotAllowed, "仲有 test case 未剔" unless all_answered?
    raise NotAllowed, "全部 pass 嘅話請直接 sign-off" if all_passed?

    update!(status: :changes_requested, closed_at: Time.current)
  end
end
