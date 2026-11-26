# 交付咗嘅系統嘅一個網址或者帳戶：喺邊度登入、喺邊個名下。
# 客戶喺 portal「系統資料」頁睇到。唔好喺度放密碼。
class SystemLink < ApplicationRecord
  belongs_to :project

  KINDS = %w[site admin service doc].freeze
  enum :kind, KINDS.each_with_index.to_h, prefix: :kind

  KIND_LABELS = {
    "site" => "對外網站", "admin" => "管理後台", "service" => "第三方服務同帳戶", "doc" => "文件同手冊"
  }.freeze
  KIND_ICONS = { "site" => "globe", "admin" => "layout-dashboard", "service" => "key-round", "doc" => "book-open" }.freeze

  normalizes :url, with: ->(u) { u.strip.presence }

  validates :label, presence: { message: "唔可以留空" }
  validate :url_is_web_address

  def kind_label = KIND_LABELS.fetch(kind)
  def kind_icon = KIND_ICONS.fetch(kind)

  # 按類別分組，每組跟 position 排
  def self.grouped(links)
    links.sort_by { |l| [ KINDS.index(l.kind), l.position, l.id.to_i ] }.group_by(&:kind)
  end

  private
    # 只准 http／https，唔俾 javascript: 呢類連結入到客戶頁面
    def url_is_web_address
      return if url.blank?

      uri = URI.parse(url)
      ok = uri.is_a?(URI::HTTP) && uri.host.present?
      errors.add(:url, "要係 http:// 或者 https:// 開頭嘅網址") unless ok
    rescue URI::InvalidURIError
      errors.add(:url, "唔係有效嘅網址")
    end
end
