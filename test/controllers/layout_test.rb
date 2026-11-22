require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  setup do
    @client = clients(:yoga)
    @project = projects(:yoga_course)
  end

  test "every admin page has a title and exactly one current item in the sidebar" do
    sign_in_as users(:one)
    {
      admin_root_path => "Dashboard",
      admin_clients_path => "客戶",
      admin_client_path(@client) => "客戶",
      new_admin_client_path => "客戶",
      edit_admin_client_path(@client) => "客戶",
      new_admin_client_retainer_plan_path(@client) => "客戶",
      admin_projects_path => "Projects",
      new_admin_project_path => "Projects",
      admin_project_path(@project) => "Projects",
      edit_admin_project_path(@project) => "Projects",
      new_admin_project_test_case_path(@project) => "Projects",
      new_admin_project_change_request_path(@project) => "Projects",
      admin_tickets_path => "Tickets",
      admin_maintenance_report_path => "月尾報告",
      admin_retention_path => "Retention",
      admin_sign_offs_path => "Sign-offs"
    }.each do |path, current|
      get path
      assert_response :success, path
      assert_select "html[lang=zh-HK]"
      assert_select "title", { text: /\S · UAT Portal\z/ }, "#{path} has no page title"
      assert_select ".app-sidebar [aria-current=page]", { count: 1, text: /#{current}/ }, path
    end
  end

  test "the client portal shows tabs only when the client has a retainer" do
    sign_in_as users(:two)
    get portal_projects_path
    assert_select "title", "我嘅 project · UAT Portal"
    assert_select ".app-tabs", count: 0
    assert_select ".app-banner", count: 0
    assert_select ".app-sidebar", count: 0

    @client.create_retainer_plan!(monthly_fee_hkd: 2600, starts_on: Date.current.beginning_of_month)
    get portal_retainer_path
    assert_select ".app-tabs [aria-current=page]", text: /月費維護/
    get portal_project_path(@project)
    assert_select ".app-tabs [aria-current=page]", text: /我嘅 project/
  end

  test "an admin looking at the portal sees a preview banner" do
    sign_in_as users(:one)
    get portal_project_path(@project)
    assert_select ".app-banner", text: /Admin 預覽緊客戶 portal/
  end

  test "a notice is a status toast that the next page doesn't repeat" do
    sign_in_as users(:one)
    post admin_clients_path, params: { client: { name: "新客", code: "NEWC", contact_email: "hi@newc.example" } }
    follow_redirect!
    assert_select ".toast[role=status]", text: /已新增客戶 新客/

    get admin_clients_path
    assert_select ".toast", count: 0
  end

  test "a form with errors marks the fields and lists the problems" do
    sign_in_as users(:one)
    post admin_clients_path, params: { client: { name: "", code: "", contact_email: "" } }
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /個地方要改/
    assert_select "input#client_name.input[aria-invalid=true][aria-describedby=client_name_error]"
    assert_select "p#client_name_error.field-error"
    assert_select ".field_with_errors", count: 0
  end
end
