class Project < ApplicationRecord
  belongs_to :client
  has_many :test_cases, -> { order(:code) }, dependent: :destroy

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

  # 下一個 TC 編號，例如 TC-01、TC-02
  def next_test_case_code
    last = test_cases.pluck(:code).filter_map { |c| c[/\ATC-(\d+)\z/, 1]&.to_i }.max || 0
    format("TC-%02d", last + 1)
  end
end
