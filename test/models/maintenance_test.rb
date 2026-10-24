require "test_helper"

class MaintenanceTest < ActiveSupport::TestCase
  setup do
    @project = projects(:yoga_course)
    @project.update!(phase: :maintenance)
    @client_user = users(:two)
    @admin = users(:one)
  end

  def new_ticket(**attrs)
    @project.tickets.create!({ opened_by: @client_user, title: "報名表冇反應", body: "撳提交冇反應" }.merge(attrs))
  end

  test "tickets are numbered per client" do
    assert_equal "TKT-DEMOYOGA-001", new_ticket.doc_number
    assert_equal "TKT-DEMOYOGA-002", new_ticket.doc_number
  end

  test "tickets only open after launch" do
    @project.update!(phase: :development)
    ticket = @project.tickets.build(opened_by: @client_user, title: "x", body: "y")
    assert_not ticket.valid?
    assert_match "上線", ticket.errors.full_messages.to_sentence
  end

  test "resolving stamps resolved_at and reopening clears it" do
    ticket = new_ticket
    ticket.update!(status: :resolved)
    assert_not_nil ticket.resolved_at
    ticket.update!(status: :in_progress)
    assert_nil ticket.resolved_at
  end

  test "monthly report counts only that month" do
    travel_to Time.zone.local(2026, 9, 28, 10) do
      t = new_ticket(title: "九月單")
      t.logs.create!(user: @admin, logged_on: Date.new(2026, 9, 28), minutes: 45, note: "查 log")
    end
    travel_to Time.zone.local(2026, 10, 3, 10) do
      september = @project.tickets.find_by(title: "九月單")
      september.logs.create!(user: @admin, logged_on: Date.new(2026, 10, 3), minutes: 30, note: "修好")
      september.update!(status: :resolved)
      new_ticket(title: "十月單").logs.create!(user: @admin, logged_on: Date.new(2026, 10, 3), minutes: 90, note: "改 CSS")
    end

    october = MaintenanceReport.new(client: clients(:yoga), month: Date.new(2026, 10, 1))
    assert_equal 1, october.opened.size
    assert_equal 1, october.resolved.size
    assert_equal 120, october.total_minutes
    assert_equal [ 30, 90 ], october.minutes_by_ticket.map(&:last)
    assert_equal [ "十月單" ], october.still_open.map(&:title)

    september = MaintenanceReport.new(client: clients(:yoga), month: Date.new(2026, 9, 1))
    assert_equal 45, september.total_minutes
  end

  test "another client's tickets stay out of the report" do
    music = projects(:music_app)
    music.update!(phase: :maintenance)
    music.tickets.create!(opened_by: users(:other_client), title: "其他客", body: "x")
    report = MaintenanceReport.new(client: clients(:yoga), month: Date.current)
    assert_empty report.opened
  end

  test "total minutes ignores an unsaved log" do
    ticket = new_ticket
    ticket.logs.create!(user: @admin, logged_on: Date.current, minutes: 35, note: "修好")
    ticket.logs.build(user: @admin, logged_on: Date.current, minutes: 30)
    assert_equal 35, ticket.total_minutes
  end

  test "formats minutes as hours" do
    assert_equal "1 小時 30 分鐘", MaintenanceReport.format_minutes(90)
    assert_equal "2 小時", MaintenanceReport.format_minutes(120)
    assert_equal "0 分鐘", MaintenanceReport.format_minutes(0)
  end
end
