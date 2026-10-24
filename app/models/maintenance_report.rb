# 一個客戶一個月嘅 maintenance 總結：用嚟月尾交畀客，或者對 retainer 時數
class MaintenanceReport
  attr_reader :client, :month

  def initialize(client:, month:)
    @client = client
    @month = month.beginning_of_month
  end

  def range = month.beginning_of_month..month.end_of_month
  def time_range = month.beginning_of_month.beginning_of_day..month.end_of_month.end_of_day

  def tickets = Ticket.joins(:project).where(projects: { client_id: client.id })

  def opened = tickets.where(created_at: time_range).order(:created_at)
  def resolved = tickets.where(resolved_at: time_range).order(:resolved_at)
  def still_open = tickets.unresolved.where(created_at: ..time_range.end).order(:created_at)

  def logs
    TicketLog.joins(ticket: :project).where(projects: { client_id: client.id }, logged_on: range)
             .includes(:ticket).order(:logged_on, :created_at)
  end

  def total_minutes = logs.sum(:minutes)

  # 呢個月有做過嘢嘅 ticket，連每單用咗幾耐
  def minutes_by_ticket
    logs.group_by(&:ticket).transform_values { |ls| ls.sum(&:minutes) }.sort_by { |t, _| t.doc_number }
  end

  def self.format_minutes(minutes)
    h, m = minutes.divmod(60)
    [ (h.positive? ? "#{h} 小時" : nil), (m.positive? || h.zero? ? "#{m} 分鐘" : nil) ].compact.join(" ")
  end
end
