class TestResult < ApplicationRecord
  belongs_to :uat_round
  belongs_to :test_case
  has_many_attached :screenshots

  enum :status, { pending: 0, pass: 1, fail: 2, blocked: 3 }, prefix: :status

  STATUS_LABELS = { "pending" => "未測", "pass" => "Pass", "fail" => "Fail", "blocked" => "測唔到" }.freeze
  MAX_SCREENSHOT_BYTES = 10.megabytes

  validate :round_still_open, on: :update
  validates :comment, presence: { message: "要寫低咩問題" }, if: -> { status_fail? || status_blocked? }
  validate :screenshots_are_images

  def status_label = STATUS_LABELS.fetch(status)

  private
    def round_still_open
      errors.add(:base, "呢個 round 已經關咗，唔可以再改") unless uat_round.status_open?
    end

    def screenshots_are_images
      screenshots.each do |s|
        errors.add(:screenshots, "只可以上載圖片") unless s.content_type.to_s.start_with?("image/")
        errors.add(:screenshots, "每張唔可以大過 10MB") if s.byte_size.to_i > MAX_SCREENSHOT_BYTES
      end
    end
end
