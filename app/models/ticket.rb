# Maintenance ticket：上線後客戶報問題或者要求小改動
class Ticket < ApplicationRecord
  belongs_to :project
  belongs_to :opened_by, class_name: "User"
  has_many :logs, -> { order(:logged_on, :created_at) }, class_name: "TicketLog", dependent: :destroy
  has_many_attached :screenshots

  enum :priority, { low: 0, normal: 1, urgent: 2 }, prefix: :priority
  enum :status, { open: 0, in_progress: 1, waiting_client: 2, resolved: 3 }, prefix: :status

  PRIORITY_LABELS = { "low" => "唔急", "normal" => "一般", "urgent" => "緊急" }.freeze
  STATUS_LABELS = { "open" => "未處理", "in_progress" => "處理中", "waiting_client" => "等客戶回覆", "resolved" => "已解決" }.freeze
  OPEN_PHASES = %w[launch maintenance].freeze

  scope :unresolved, -> { where.not(status: :resolved) }

  before_validation :assign_doc_number, on: :create
  before_save :track_resolved_at, if: :will_save_change_to_status?

  validates :doc_number, presence: true, uniqueness: true
  validates :title, :body, presence: true
  validate :project_accepts_tickets, on: :create
  validate :screenshots_are_images

  def priority_label = PRIORITY_LABELS.fetch(priority)
  def status_label = STATUS_LABELS.fetch(status)
  # 只計已儲存嘅記錄（admin 頁會 build 一條未儲存嘅做表格預設值）
  def total_minutes = logs.reject(&:new_record?).sum(&:minutes)

  private
    def assign_doc_number
      return if doc_number.present? || project.nil?

      n = Ticket.joins(:project).where(projects: { client_id: project.client_id }).count + 1
      self.doc_number = format("TKT-%s-%03d", project.client.code, n)
    end

    def track_resolved_at
      self.resolved_at = status_resolved? ? (resolved_at || Time.current) : nil
    end

    def project_accepts_tickets
      return if project.nil? || OPEN_PHASES.include?(project.phase)

      errors.add(:base, "Project 上線之後先可以開 maintenance ticket")
    end

    def screenshots_are_images
      screenshots.each do |s|
        errors.add(:screenshots, "只可以上載圖片") unless s.content_type.to_s.start_with?("image/")
        errors.add(:screenshots, "每張唔可以大過 10MB") if s.byte_size.to_i > 10.megabytes
      end
    end
end
