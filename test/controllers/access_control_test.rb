require "test_helper"

class AccessControlTest < ActionDispatch::IntegrationTest
  test "admin lands on the dashboard" do
    sign_in_as users(:one)
    get root_path
    assert_redirected_to admin_root_path
    follow_redirect!
    assert_response :success
  end

  test "client lands on their portal" do
    sign_in_as users(:two)
    get root_path
    assert_redirected_to portal_projects_path
  end

  test "client cannot open the admin area" do
    sign_in_as users(:two)
    get admin_projects_path
    assert_response :forbidden
  end

  test "client only sees their own projects" do
    sign_in_as users(:two)
    get portal_projects_path
    assert_match "網上課程", response.body
    assert_no_match "Music app", response.body

    get portal_project_path(projects(:music_app))
    assert_response :not_found
  end

  test "admin can create a test case with the next code" do
    sign_in_as users(:one)
    project = projects(:yoga_course)
    get new_admin_project_test_case_path(project)
    assert_match "TC-03", response.body

    assert_difference -> { project.test_cases.count }, 1 do
      post admin_project_test_cases_path(project), params: { test_case: { code: "TC-03", title: "手機版", source: "client" } }
    end
    assert_redirected_to admin_project_path(project)
  end

  test "admin pages render" do
    sign_in_as users(:one)
    [ admin_clients_path, admin_client_path(clients(:yoga)), admin_projects_path,
      admin_project_path(projects(:yoga_course)), new_admin_project_path, edit_admin_project_path(projects(:yoga_course)) ].each do |path|
      get path
      assert_response :success, "#{path} failed"
    end
  end
end
