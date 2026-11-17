require "test_helper"

class RetainerTest < ActiveSupport::TestCase
  setup do
    @client = clients(:yoga)
    @project = projects(:yoga_course)
    @project.update!(phase: :maintenance)
    @client_user = users(:two)
    @plan = @client.create_retainer_plan!(monthly_fee_hkd: 2600, included_rounds: 3, extra_round_hkd: 500,
                                          starts_on: Date.current.beginning_of_month, notice_days: 30)
  end

  def new_ticket(**attrs)
    @project.tickets.create!({ opened_by: @client_user, title: "改文字", body: "改主頁標題" }.merge(attrs))
  end

  test "only change tickets in the month count as rounds" do
    2.times { new_ticket }
    new_ticket(kind: :fault)
    travel_to(1.month.ago) { new_ticket }
    assert_equal 2, @plan.rounds_used(Date.current)
    assert_equal 1, @plan.rounds_left(Date.current)
  end

  test "a change ticket past the included rounds needs the client's confirmation" do
    3.times { new_ticket }
    assert @plan.next_round_is_extra?

    ticket = @project.tickets.build(opened_by: @client_user, title: "第四輪", body: "再改")
    assert_not ticket.valid?
    assert_match "HK$500", ticket.errors.full_messages.to_sentence

    ticket.confirm_extra_round = true
    assert ticket.save
    assert ticket.extra_round?
    assert_not_nil ticket.extra_round_confirmed_at
    assert_equal 1, @plan.extra_rounds(Date.current)
    assert_equal 500, @plan.extra_amount_hkd(Date.current)
    assert_equal 3100, @plan.amount_due_hkd(Date.current)
  end

  test "a fault ticket never needs confirmation" do
    3.times { new_ticket }
    ticket = new_ticket(kind: :fault)
    assert_not ticket.extra_round?
  end

  test "no plan means no rounds rule" do
    @plan.destroy!
    4.times { new_ticket }
    assert Ticket.where(extra_round: true).none?
  end

  test "admin turning an extra round into a fault drops the charge" do
    3.times { new_ticket }
    ticket = new_ticket(confirm_extra_round: true)
    assert ticket.extra_round?

    ticket.update!(kind: :fault)
    assert_not ticket.reload.extra_round?
    assert_nil ticket.extra_round_confirmed_at
    assert_equal 0, @plan.extra_amount_hkd(Date.current)
  end

  test "giving notice sets the end date and lists the handover" do
    @plan.give_notice!(by: :client, on: Date.new(2026, 11, 20))
    assert_equal Date.new(2026, 12, 20), @plan.ends_on
    assert_equal RetainerPlan::DEFAULT_HANDOVER_ITEMS.size, @plan.handover_items.count
    assert @plan.handover_items.any?(&:side_client?)
    assert @plan.handover_items.any?(&:side_provider?)
    assert_not @plan.handover_complete?

    @plan.handover_items.each { |i| i.mark!(done: true, user: users(:one)) }
    assert @plan.reload.handover_complete?

    @plan.withdraw_notice!
    assert_nil @plan.reload.ends_on
    assert @plan.handover_items.empty?
  end

  test "the plan stops being active after the notice period" do
    @plan.give_notice!(by: :provider, on: Date.current)
    assert @plan.active_on?(Date.current + 30)
    assert_not @plan.active_on?(Date.current + 31)
    assert @plan.billable_in?(Date.current + 30)
    assert_not @plan.billable_in?((Date.current + 31).next_month)
  end

  test "clients can only tick their own side of the handover" do
    @plan.give_notice!(by: :client)
    client_item = @plan.handover_items.detect(&:side_client?)
    provider_item = @plan.handover_items.detect(&:side_provider?)

    assert client_item.editable_by?(@client_user)
    assert_not provider_item.editable_by?(@client_user)
    assert_not client_item.editable_by?(users(:other_client))
    assert provider_item.editable_by?(users(:one))
  end

  test "retention signals" do
    row = RetentionRow.new(client: @client, today: Date.current)
    assert_equal :healthy, row.signal

    music = clients(:music)
    projects(:music_app).update!(phase: :launch)
    assert_equal :no_plan, RetentionRow.new(client: music).signal

    @plan.update!(starts_on: 90.days.ago.to_date)
    assert_equal :low_usage, RetentionRow.new(client: @client).signal
    new_ticket
    assert_equal :healthy, RetentionRow.new(client: @client).signal

    @plan.give_notice!(by: :client)
    assert_equal :notice, RetentionRow.new(client: @client).signal
    assert_equal :ended, RetentionRow.new(client: @client, today: Date.current + 31).signal
  end

  test "frequent extra rounds suggest an upgrade" do
    @plan.update!(starts_on: 2.months.ago.to_date.beginning_of_month)
    [ 1.month.ago, Time.current ].each do |t|
      travel_to(t) do
        3.times { new_ticket }
        new_ticket(confirm_extra_round: true)
      end
    end
    assert_equal 2, RetentionRow.new(client: @client).months_with_extra
    assert_equal :upsell, RetentionRow.new(client: @client).signal
  end

  test "monthly recurring total only counts active plans" do
    assert_equal 2600, RetentionRow.monthly_recurring_hkd
    @plan.give_notice!(by: :client, on: 40.days.ago.to_date)
    assert_equal 0, RetentionRow.monthly_recurring_hkd
  end
end
