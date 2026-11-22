# Retention 儀表板一行：一個客戶嘅 retainer 用量，加流失／升級訊號
class RetentionRow
  LOW_USAGE_DAYS = 60

  # 訊號 => [ 標籤, 色調 ]；次序 = 嚴重程度
  SIGNALS = {
    ended: [ "已完約", :neutral ],
    notice: [ "已通知終止", :danger ],
    no_plan: [ "已上線但未有 retainer", :warning ],
    upsell: [ "經常超出，可建議升級", :accent ],
    low_usage: [ "用量偏低，主動約傾", :warning ],
    healthy: [ "正常", :success ]
  }.freeze

  attr_reader :client, :today

  def self.all(today: Date.current)
    Client.includes(:retainer_plan, :projects).order(:name)
          .map { |c| new(client: c, today: today) }.select(&:relevant?)
  end

  # 而家生效緊嘅月費總和（未完約嘅都計）
  def self.monthly_recurring_hkd(today: Date.current)
    RetainerPlan.all.select { |p| p.active_on?(today) }.sum(&:monthly_fee_hkd)
  end

  def initialize(client:, today: Date.current)
    @client = client
    @today = today
  end

  def plan = client.retainer_plan
  def live_project? = client.projects.any? { |p| Ticket::OPEN_PHASES.include?(p.phase) }
  def relevant? = plan.present? || live_project?

  def rounds_used = plan&.rounds_used(today)
  def last_ticket_at = client.tickets.maximum(:created_at)
  def last_change_at = client.tickets.kind_change.maximum(:created_at)

  def recent_months = (0..2).map { |i| (today << i).beginning_of_month }
  def months_with_extra = plan ? recent_months.count { |m| plan.extra_rounds(m).positive? } : 0

  def signal
    return :ended if plan&.ends_on && plan.ends_on < today
    return :notice if plan&.notice_given?
    return :no_plan if plan.nil?
    return :upsell if months_with_extra >= 2
    return :low_usage if low_usage?

    :healthy
  end

  def signal_label = SIGNALS.fetch(signal).first
  def signal_tone = SIGNALS.fetch(signal).last

  # 簽咗超過 60 日，但 60 日內冇開過修改 ticket
  def low_usage?
    return false unless plan&.active_on?(today)
    return false if (today - plan.starts_on).to_i < LOW_USAGE_DAYS

    last = last_change_at
    last.nil? || last.to_date < today - LOW_USAGE_DAYS
  end
end
