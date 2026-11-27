class Project < ApplicationRecord
  belongs_to :client
  has_many :test_cases, -> { order(:code) }, dependent: :destroy
  has_many :uat_rounds, -> { order(:number) }, dependent: :destroy
  has_many :change_requests, -> { order(:created_at) }, dependent: :destroy
  has_many :sign_offs, dependent: :restrict_with_error
  has_many :tickets, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :external_sign_offs, -> { order(:position, :signed_on, :id) }, dependent: :destroy
  has_many :system_links, dependent: :destroy

  # 跟 SOP 嘅交付階段，次序唔好改（存落 DB 嘅係數字）
  PHASES = %w[requirement design development sat uat launch maintenance].freeze
  enum :phase, PHASES.each_with_index.to_h, prefix: :phase

  PHASE_LABELS = {
    "requirement" => "Requirement", "design" => "Design", "development" => "Development",
    "sat" => "SAT", "uat" => "UAT", "launch" => "Launch", "maintenance" => "Maintenance"
  }.freeze

  validates :name, presence: true
  validates :max_uat_rounds, numericality: { only_integer: true, greater_than: 0 }

  def phase_index = PHASES.index(phase)
  def phase_label = PHASE_LABELS.fetch(phase)

  # UAT 總共准開幾多 round = 合約包嘅 + 已批 CR 加嘅
  def allowed_uat_rounds
    max_uat_rounds + change_requests.select(&:status_approved?).sum(&:extra_rounds)
  end

  def accepts_tickets? = Ticket::OPEN_PHASES.include?(phase)

  def open_round = uat_rounds.detect(&:status_open?)
  def latest_round = uat_rounds.last
  def signed_off? = uat_rounds.any?(&:status_signed_off?)

  # UAT 喺系統以外簽咗最終驗收（見 ExternalSignOff）
  def final_external_sign_off = external_sign_offs.select(&:final?).max_by(&:signed_on)
  def accepted_externally? = final_external_sign_off.present?
  def uat_accepted? = signed_off? || accepted_externally?

  # UAT 驗收完成嗰日：系統內 sign-off 或者系統外最終驗收
  def uat_accepted_on
    in_system = sign_offs.map(&:signed_at).min&.to_date
    [ in_system, final_external_sign_off&.signed_on ].compact.min
  end

  # 唔可以開新 round 嘅原因；nil = 可以開
  def cannot_open_round_reason
    return "已經 sign-off，唔使再開 round" if signed_off?
    return "UAT 已喺系統外簽署驗收，唔使再開 round" if accepted_externally?
    return "Round #{open_round.number} 仲未完" if open_round
    return "未有 test case" if test_cases.empty?
    return "已用晒 #{allowed_uat_rounds} 個 round，要先開 CR 並批核" if uat_rounds.size >= allowed_uat_rounds
    nil
  end

  def open_next_round!
    reason = cannot_open_round_reason
    raise UatRound::NotAllowed, reason if reason

    transaction do
      round = uat_rounds.create!(number: uat_rounds.size + 1, opened_at: Time.current)
      test_cases.each { |tc| round.test_results.create!(test_case: tc) }
      update!(phase: :uat) unless phase_uat?
      round
    end
  end

  # 將未有 IT 結果嘅 test case 一次過記做已測通過；有結果嘅（包括未過）唔郁。回傳改咗幾多條。
  def mark_untested_cases_it_passed!(on: Date.current)
    test_cases.where(it_status: :untested).update_all(it_status: TestCase.it_statuses.fetch("pass"), it_tested_on: on, updated_at: Time.current)
  end

  # 下一個 TC 編號，例如 TC-01、TC-02
  def next_test_case_code
    last = test_cases.pluck(:code).filter_map { |c| c[/\ATC-(\d+)\z/, 1]&.to_i }.max || 0
    format("TC-%02d", last + 1)
  end
end
