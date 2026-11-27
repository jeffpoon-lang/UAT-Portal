# Small view helpers shared by the admin pages and the client portal.
module UiHelper
  # Literal class names so Tailwind finds every one of them
  BADGE_CLASSES = {
    neutral: "badge badge-neutral", accent: "badge badge-accent", success: "badge badge-success",
    warning: "badge badge-warning", danger: "badge badge-danger", violet: "badge badge-violet",
    danger_solid: "badge badge-danger-solid"
  }.freeze

  RESULT_TONES = { "pending" => :neutral, "pass" => :success, "fail" => :danger, "blocked" => :warning }.freeze
  TICKET_STATUS_TONES = { "open" => :danger, "in_progress" => :accent, "waiting_client" => :warning, "resolved" => :success }.freeze
  IT_CHECK_TONES = { "untested" => :neutral, "pass" => :success, "fail" => :danger }.freeze
  ROUND_TONES = { "open" => :accent, "changes_requested" => :warning, "signed_off" => :success }.freeze
  CR_TONES = { "pending" => :warning, "approved" => :success, "rejected" => :neutral }.freeze
  AI_CATEGORY_TONES = { "bug" => :danger, "change_request" => :violet, "unclear" => :neutral }.freeze

  # Times are shown in UK time, where the developer works
  DISPLAY_TIME_ZONE = "Europe/London"
  TIME_FORMATS = { datetime: "%Y-%m-%d %H:%M", date: "%Y-%m-%d", short: "%m-%d", zone: "%Y-%m-%d %H:%M %Z" }.freeze

  def badge(text, tone = :neutral, icon: nil)
    tag.span(class: BADGE_CLASSES.fetch(tone)) do
      safe_join([ (icon(icon, class: "size-3") if icon), text ].compact)
    end
  end

  def result_badge(result) = badge(result.status_label, RESULT_TONES.fetch(result.status))
  def it_check_badge(test_case) = badge(test_case.it_status_label, IT_CHECK_TONES.fetch(test_case.it_status))
  def round_status_badge(round, audience = :admin) = badge(round.status_label(audience), ROUND_TONES.fetch(round.status))
  def ticket_status_badge(ticket) = badge(ticket.status_label, TICKET_STATUS_TONES.fetch(ticket.status))

  def ticket_badges(ticket)
    safe_join([
      ticket_status_badge(ticket),
      (badge("系統故障", :neutral) if ticket.kind_fault?),
      (badge("額外一輪", :warning) if ticket.extra_round?),
      (badge("緊急", :danger_solid) if ticket.priority_urgent?)
    ].compact, " ")
  end

  def ai_category_badge(category)
    badge(AiSummaryService::CATEGORY_LABELS.fetch(category, category), AI_CATEGORY_TONES.fetch(category, :neutral))
  end

  def local_time(time, format = :datetime)
    return if time.nil?

    t = time.in_time_zone(DISPLAY_TIME_ZONE)
    tag.time(t.strftime(TIME_FORMATS.fetch(format)), datetime: t.iso8601)
  end

  # "3 日前", with the exact time on hover
  def time_ago_zh(time, now: Time.current)
    seconds = (now - time).to_i
    text =
      if seconds < 60 then "啱啱"
      elsif seconds < 3600 then "#{seconds / 60} 分鐘前"
      elsif seconds < 86_400 then "#{seconds / 3600} 個鐘前"
      elsif seconds < 86_400 * 30 then "#{seconds / 86_400} 日前"
      elsif seconds < 86_400 * 365 then "#{seconds / (86_400 * 30)} 個月前"
      else "#{seconds / (86_400 * 365)} 年前"
      end
    t = time.in_time_zone(DISPLAY_TIME_ZONE)
    tag.time(text, datetime: t.iso8601, title: t.strftime(TIME_FORMATS[:datetime]))
  end

  # The heading block at the top of every page. It also sets <title>, so
  # every page gets one. Buttons go in the block.
  def page_header(title, subtitle: nil, crumbs: [], &block)
    content_for(:title, title) unless content_for?(:title)
    actions = capture(&block) if block
    render "ui/page_header", title: title, subtitle: subtitle, crumbs: crumbs, actions: actions
  end

  CALLOUT_ICONS = { info: "circle-alert", warning: "circle-alert", danger: "circle-alert", violet: "circle-alert", success: "circle-check" }.freeze
  CALLOUT_CLASSES = {
    info: "callout callout-info", warning: "callout callout-warning", danger: "callout callout-danger",
    violet: "callout callout-violet", success: "callout callout-success"
  }.freeze

  def callout(tone = :info, css: nil, role: nil, &block)
    tag.div(class: [ CALLOUT_CLASSES.fetch(tone), css ].compact.join(" "), role: role) do
      safe_join([ icon(CALLOUT_ICONS.fetch(tone)), tag.div(capture(&block), class: "min-w-0 flex-1") ])
    end
  end

  # The squirrel with a magnifying glass, looking for what isn't there yet
  def empty_state(title, body: nil, &block)
    action = capture(&block) if block
    tag.div(class: "empty") do
      safe_join([
        icon("mascot-search", class: "mb-3 w-32 text-fg-muted"),
        tag.p(title, class: "text-sm font-medium text-fg"),
        (tag.p(body, class: "mt-1 max-w-sm text-sm text-fg-subtle") if body),
        (tag.div(action, class: "mt-4") if action)
      ].compact)
    end
  end

  # <title>: "頁名 · UAT Portal"
  def page_title
    content_for?(:title) ? "#{content_for(:title)} · UAT Portal" : "UAT Portal"
  end

  def percent(part, whole)
    whole.to_i.zero? ? 100 : [ part * 100 / whole, 100 ].min
  end
end
