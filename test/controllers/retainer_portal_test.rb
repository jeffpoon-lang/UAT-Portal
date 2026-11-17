require "test_helper"

class RetainerPortalTest < ActionDispatch::IntegrationTest
  setup do
    @client = clients(:yoga)
    @project = projects(:yoga_course)
    @project.update!(phase: :maintenance)
  end

  def ticket_params(**extra)
    { ticket: { title: "改標題", body: "主頁標題換字", priority: "normal", kind: "change" }.merge(extra) }
  end

  test "admin sets up a retainer and the client uses up the rounds" do
    sign_in_as users(:one)
    get new_admin_client_retainer_plan_path(@client)
    assert_response :success
    post admin_client_retainer_plan_path(@client), params: { retainer_plan: {
      monthly_fee_hkd: 2600, included_rounds: 3, extra_round_hkd: 500,
      starts_on: Date.current.beginning_of_month, notice_days: 30, quote_ref: "QUO-DEMO-006" } }
    assert_redirected_to admin_client_path(@client)
    plan = @client.reload.retainer_plan
    assert_equal 2600, plan.monthly_fee_hkd
    sign_out

    sign_in_as users(:two)
    3.times { post portal_project_tickets_path(@project), params: ticket_params }
    get portal_project_path(@project)
    assert_match "<strong class=\"text-lg\">3</strong> ／ 3 輪", response.body

    get new_portal_project_ticket_path(@project)
    assert_match "我明白，確認開額外一輪", response.body

    assert_no_difference -> { Ticket.count } do
      post portal_project_tickets_path(@project), params: ticket_params
    end
    assert_response :unprocessable_entity
    assert_match "另收 HK$500", response.body

    post portal_project_tickets_path(@project), params: ticket_params(confirm_extra_round: "1")
    assert Ticket.last.extra_round?

    post portal_project_tickets_path(@project), params: ticket_params(kind: "fault", title: "付款頁 500 error")
    assert_not Ticket.last.extra_round?
    sign_out

    sign_in_as users(:one)
    get admin_maintenance_report_path(client_id: @client.id, month: Date.current.strftime("%Y-%m"))
    assert_match "用咗 4 輪", response.body
    assert_match "HK$3,100", response.body

    post admin_monthly_updates_path, params: { monthly_update: {
      client_id: @client.id, month: Date.current.strftime("%Y-%m"), done_summary: "主頁改咗四次", next_steps: "下月加 FAQ" } }
    follow_redirect!
    assert_match "主頁改咗四次", response.body
    assert_match "下月加 FAQ", response.body

    get admin_retention_path
    assert_response :success
    assert_match @client.name, response.body
    assert_match "4／3", response.body
  end

  test "notice of termination lists a handover each side can tick" do
    plan = @client.create_retainer_plan!(monthly_fee_hkd: 2600, starts_on: Date.current.beginning_of_month)

    sign_in_as users(:one)
    post give_notice_admin_client_retainer_plan_path(@client), params: { notice_given_by: "client", notice_given_on: "2026-11-20" }
    assert_redirected_to admin_client_path(@client)
    assert_equal Date.new(2026, 12, 20), plan.reload.ends_on
    get admin_client_path(@client)
    assert_match "2026-12-20", response.body
    sign_out

    client_item = plan.handover_items.detect(&:side_client?)
    provider_item = plan.handover_items.detect(&:side_provider?)

    sign_in_as users(:two)
    get portal_retainer_path
    assert_response :success
    assert_match client_item.title, response.body

    patch portal_handover_item_path(client_item), params: { done: "1" }
    assert_redirected_to portal_retainer_path
    assert client_item.reload.done?

    patch portal_handover_item_path(provider_item), params: { done: "1" }
    assert_response :forbidden
    assert_not provider_item.reload.done?
    sign_out

    sign_in_as users(:other_client)
    patch portal_handover_item_path(client_item), params: { done: "0" }
    assert_response :not_found
    assert client_item.reload.done?
    sign_out

    sign_in_as users(:one)
    patch admin_handover_item_path(provider_item), params: { done: "1" }
    assert provider_item.reload.done?
    post withdraw_notice_admin_client_retainer_plan_path(@client)
    assert_nil plan.reload.notice_given_on
  end

  test "admin can reclassify a ticket as a fault" do
    @client.create_retainer_plan!(monthly_fee_hkd: 2600, included_rounds: 0, starts_on: Date.current.beginning_of_month)
    ticket = @project.tickets.create!(opened_by: users(:two), title: "x", body: "y", confirm_extra_round: true)
    assert ticket.extra_round?

    sign_in_as users(:one)
    patch admin_ticket_path(ticket), params: { ticket: { kind: "fault" } }
    assert ticket.reload.kind_fault?
    assert_not ticket.extra_round?
  end

  test "clients cannot reach retainer admin pages" do
    sign_in_as users(:two)
    get admin_retention_path
    assert_response :forbidden
    get new_admin_client_retainer_plan_path(@client)
    assert_response :forbidden
    post admin_monthly_updates_path, params: { monthly_update: { client_id: @client.id, month: "2026-11" } }
    assert_response :forbidden
  end

  test "client without a retainer is sent back from the retainer page" do
    sign_in_as users(:two)
    get portal_retainer_path
    assert_redirected_to portal_projects_path
  end
end
