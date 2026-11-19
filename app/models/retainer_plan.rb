# 上線後嘅月費維護（retainer）：每個客戶一份。
# 每月包幾多輪修改、超出每輪幾錢、通知期幾耐，全部跟報價單。
# 一張「修改」ticket 計一輪；「系統故障」唔計。
class RetainerPlan < ApplicationRecord
  belongs_to :client
  has_many :handover_items, -> { order(:position, :id) }, dependent: :destroy

  enum :notice_given_by, { client: 0, provider: 1 }, prefix: :notice_by

  NOTICE_BY_LABELS = { "client" => "客戶", "provider" => "服務提供者" }.freeze

  # 通知終止之後自動列出嘅交接清單；兩邊各自剔自己嗰份
  DEFAULT_HANDOVER_ITEMS = [
    [ :provider, "交出原始碼完整副本同技術文件" ],
    [ :provider, "將仲喺服務提供者名下嘅帳戶或自動化流程轉畀客戶" ],
    [ :provider, "開交接會議，向接手人講解系統同日常操作" ],
    [ :provider, "移除服務提供者喺所有系統嘅存取權限" ],
    [ :provider, "刪除手上嘅客戶資料副本" ],
    [ :client, "確定接手人，安排佢出席交接會議" ],
    [ :client, "喺自己帳戶重新產生 API key 同密碼" ],
    [ :client, "登入每個系統，確認可以自己管理" ],
    [ :client, "匯出一次完整資料備份" ]
  ].freeze

  validates :client_id, uniqueness: true
  validates :starts_on, presence: true
  validates :monthly_fee_hkd, :included_rounds, :extra_round_hkd,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :notice_days, numericality: { only_integer: true, greater_than: 0 }

  def notice_given? = notice_given_on.present?
  def ends_on = notice_given_on && notice_given_on + notice_days
  def notice_by_label = NOTICE_BY_LABELS[notice_given_by]

  def active_on?(date)
    date >= starts_on && (ends_on.nil? || date <= ends_on)
  end

  # 呢個月有冇任何一日係合約期內（用嚟決定月費收唔收）
  def billable_in?(month)
    m = month.beginning_of_month
    starts_on <= m.end_of_month && (ends_on.nil? || ends_on >= m)
  end

  def days_left(today = Date.current) = ends_on && (ends_on - today).to_i

  def change_tickets_in(month)
    m = month.beginning_of_month
    client.tickets.kind_change.where(created_at: m.beginning_of_day..m.end_of_month.end_of_day)
  end

  def rounds_used(month) = change_tickets_in(month).count
  def rounds_left(month) = [ included_rounds - rounds_used(month), 0 ].max
  def extra_rounds(month) = change_tickets_in(month).where(extra_round: true).count
  def extra_amount_hkd(month) = extra_rounds(month) * extra_round_hkd
  def fee_hkd(month) = billable_in?(month) ? monthly_fee_hkd : 0
  def amount_due_hkd(month) = fee_hkd(month) + extra_amount_hkd(month)

  # 今日再開一張修改 ticket 會唔會變成額外一輪
  def next_round_is_extra?(today = Date.current)
    active_on?(today) && rounds_used(today) >= included_rounds
  end

  def give_notice!(by:, on: Date.current)
    transaction do
      update!(notice_given_by: by, notice_given_on: on)
      if handover_items.none?
        DEFAULT_HANDOVER_ITEMS.each_with_index do |(side, title), i|
          handover_items.create!(side: side, title: title, position: i + 1)
        end
      end
    end
  end

  def withdraw_notice!
    transaction do
      handover_items.destroy_all
      update!(notice_given_by: nil, notice_given_on: nil)
    end
  end

  def handover_progress = [ handover_items.to_a.count(&:done?), handover_items.size ]
  def handover_complete? = handover_items.any? && handover_items.all?(&:done?)
end
