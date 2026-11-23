require "test_helper"

class UiHelperTest < ActionView::TestCase
  include IconHelper

  test "badges use a known tone" do
    assert_dom_equal %(<span class="badge badge-success">已簽署</span>), badge("已簽署", :success)
    assert_raises(KeyError) { badge("x", :purple) }
  end

  test "icons are inline SVGs hidden from screen readers unless labelled" do
    assert_match %r{\A<svg class="size-4" aria-hidden="true" focusable="false" }, icon("check")
    assert_match %(role="img" aria-label="關閉"), icon("x", label: "關閉")
    assert_raises(ArgumentError) { icon("no-such-icon") }
    assert_raises(ArgumentError) { icon("../../config/master") }
  end

  test "times are shown in UK time" do
    time = Time.utc(2026, 7, 1, 12, 30)
    assert_dom_equal %(<time datetime="2026-07-01T13:30:00+01:00">2026-07-01 13:30</time>), local_time(time)
    assert_nil local_time(nil)
  end

  test "relative times are in Cantonese" do
    now = Time.current
    assert_match ">啱啱<", time_ago_zh(now - 10, now: now)
    assert_match ">5 分鐘前<", time_ago_zh(now - 5.minutes, now: now)
    assert_match ">3 日前<", time_ago_zh(now - 3.days, now: now)
  end

  test "ticket badges add kind, extra round and urgency" do
    ticket = Ticket.new(status: :open, kind: :fault, priority: :urgent)
    html = ticket_badges(ticket)
    assert_match "未處理", html
    assert_match "系統故障", html
    assert_match "badge-danger-solid", html
  end

  test "round status reads differently for the developer and the client" do
    round = UatRound.new(status: :changes_requested)
    assert_equal "要修正", round.status_label(:admin)
    assert_equal "等 IT 修正", round.status_label(:client)
    assert_match "badge-warning", round_status_badge(round, :client)
  end

  test "percent never goes past 100 or divides by zero" do
    assert_equal 50, percent(1, 2)
    assert_equal 100, percent(5, 3)
    assert_equal 100, percent(0, 0)
  end
end
