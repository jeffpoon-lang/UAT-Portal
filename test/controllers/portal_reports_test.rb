require "test_helper"

# 客戶自己喺 portal 揀月份睇月報
class PortalReportsTest < ActionDispatch::IntegrationTest
  setup do
    @client = clients(:yoga)
    @project = projects(:yoga_course)
  end

  test "a client in maintenance gets a 月報 tab and sees this month's report" do
    @project.update!(phase: :maintenance, maintenance_start_on: Date.current.beginning_of_month << 2)
    ticket = @project.tickets.create!(opened_by: users(:two), title: "改 banner", body: "換字")
    ticket.logs.create!(user: users(:one), logged_on: Date.current, minutes: 30, note: "換好")
    MonthlyUpdate.create!(client: @client, month: Date.current, done_summary: "更新咗首頁", next_steps: "加 FAQ")

    sign_in_as users(:two)
    get portal_project_path(@project)
    assert_select ".app-tabs a[href=?]", portal_report_path, text: /月報/

    get portal_report_path
    assert_response :success
    assert_select ".app-tabs [aria-current=page]", text: /月報/
    assert_select "h1", text: /#{@client.name} · #{Date.current.strftime("%Y 年 %-m 月")}/
    assert_select "a[href=?]", portal_project_ticket_path(@project, ticket), text: ticket.doc_number
    assert_match "30 分鐘", response.body
    assert_match "更新咗首頁", response.body
    assert_select "select#month option", 3
    assert_select "select#month option[selected]", text: /進行中/
  end

  test "an earlier month can be picked, but not one outside the range" do
    @project.update!(phase: :maintenance, maintenance_start_on: Date.current.beginning_of_month << 1)
    last_month = (Date.current.beginning_of_month << 1).strftime("%Y-%m")

    sign_in_as users(:two)
    get portal_report_path(month: last_month)
    assert_select "select#month option[selected][value=?]", last_month

    get portal_report_path(month: "2020-01")
    assert_select "select#month option[selected][value=?]", Date.current.strftime("%Y-%m")
  end

  test "a client still in UAT has no report" do
    sign_in_as users(:two)
    get portal_project_path(@project)
    assert_select ".app-tabs", count: 0
    get portal_report_path
    assert_redirected_to portal_projects_path
  end

  test "the admin can preview a client's report from the admin report" do
    @project.update!(phase: :maintenance)
    sign_in_as users(:one)
    get admin_maintenance_report_path(client_id: @client.id)
    assert_select "a[href=?]", portal_report_path(client_id: @client.id, month: Date.current.strftime("%Y-%m")), text: /客戶睇到嘅版本/

    get portal_report_path(client_id: @client.id)
    assert_response :success
    assert_select "h1", text: /#{@client.name}/

    get portal_report_path
    assert_redirected_to portal_projects_path
  end
end
