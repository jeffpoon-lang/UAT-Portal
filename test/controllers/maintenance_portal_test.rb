require "test_helper"

class MaintenancePortalTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:yoga_course)
    @project.update!(phase: :maintenance)
  end

  test "client opens a ticket, admin logs time and resolves it" do
    sign_in_as users(:two)
    get portal_project_path(@project)
    assert_match "報問題／要求改動", response.body

    post portal_project_tickets_path(@project), params: { ticket: {
      title: "報名表冇反應", body: "撳提交之後冇反應", priority: "urgent",
      screenshots: [ fixture_file_upload("screenshot.png", "image/png") ] } }
    ticket = Ticket.last
    assert_redirected_to portal_project_ticket_path(@project, ticket)
    assert_equal 1, ticket.screenshots.count
    assert ticket.priority_urgent?
    sign_out

    sign_in_as users(:one)
    get admin_root_path
    assert_match "其中 <strong>1</strong> 張緊急", response.body

    post admin_ticket_logs_path(ticket), params: { ticket_log: { logged_on: Date.current, minutes: 40, note: "修好 form validation" } }
    assert ticket.reload.status_in_progress?
    patch admin_ticket_path(ticket), params: { ticket: { status: "resolved" } }
    assert ticket.reload.status_resolved?

    get admin_maintenance_report_path(client_id: clients(:yoga).id, month: Date.current.strftime("%Y-%m"))
    assert_response :success
    assert_match "40 分鐘", response.body
    assert_match ticket.doc_number, response.body
    sign_out

    sign_in_as users(:two)
    get portal_project_ticket_path(@project, ticket)
    assert_match "修好 form validation", response.body
  end

  test "client cannot open a ticket before launch" do
    @project.update!(phase: :development)
    sign_in_as users(:two)
    get new_portal_project_ticket_path(@project)
    assert_redirected_to portal_project_path(@project)
  end

  test "client cannot see another client's ticket" do
    music = projects(:music_app)
    music.update!(phase: :maintenance)
    ticket = music.tickets.create!(opened_by: users(:other_client), title: "x", body: "y")
    sign_in_as users(:two)
    get portal_project_ticket_path(music, ticket)
    assert_response :not_found
  end

  test "client cannot reach admin tickets or reports" do
    sign_in_as users(:two)
    get admin_tickets_path
    assert_response :forbidden
    get admin_maintenance_report_path
    assert_response :forbidden
  end

  test "AI summary without a key shows a friendly error" do
    @project.update!(phase: :uat)
    round = @project.open_next_round!
    round.test_results.each { |r| r.update!(status: :fail, comment: "壞咗") }
    sign_in_as users(:one)
    original = ENV.delete("OPENAI_API_KEY")
    post summarise_admin_project_uat_round_path(@project, round)
    follow_redirect!
    assert_match "未設定 OPENAI_API_KEY", response.body
  ensure
    ENV["OPENAI_API_KEY"] = original if original
  end

  test "ticket and report pages render" do
    @project.tickets.create!(opened_by: users(:two), title: "x", body: "y")
    sign_in_as users(:one)
    [ admin_tickets_path, admin_tickets_path(filter: "all"), admin_ticket_path(Ticket.last), admin_maintenance_report_path ].each do |path|
      get path
      assert_response :success, path
    end
  end
end
