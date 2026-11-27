require "test_helper"

# IT 自己嘅測試紀錄：admin 記，客戶只見到通過嗰啲
class ItChecksTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:yoga_course)
    @checkout = test_cases(:checkout)
    @payment = test_cases(:payment)
  end

  test "admin records an IT result on a test case" do
    sign_in_as users(:one)
    get edit_admin_project_test_case_path(@project, @checkout)
    assert_response :success
    assert_match "IT 測試紀錄", response.body

    patch admin_project_test_case_path(@project, @checkout),
          params: { test_case: { it_status: "pass", it_tested_on: Date.current.to_s, it_note: "喺測試站用真帳戶試過" } }
    assert_redirected_to admin_project_path(@project)
    assert @checkout.reload.it_pass?
    assert_equal "喺測試站用真帳戶試過", @checkout.it_note

    follow_redirect!
    assert_match "IT 已測通過", response.body
    assert_match "喺測試站用真帳戶試過", response.body
  end

  test "a future IT test date is rejected" do
    sign_in_as users(:one)
    patch admin_project_test_case_path(@project, @checkout),
          params: { test_case: { it_status: "pass", it_tested_on: (Date.current + 2).to_s } }
    assert_response :unprocessable_entity
    assert @checkout.reload.it_untested?
  end

  test "admin marks every unrecorded case as passed in one go" do
    @payment.update!(it_status: :fail, it_note: "收唔到 email")
    sign_in_as users(:one)

    post mark_it_passed_admin_project_test_cases_path(@project)
    assert_redirected_to admin_project_path(@project)
    assert @checkout.reload.it_pass?
    assert @payment.reload.it_fail?, "a recorded failure must not be overwritten"

    follow_redirect!
    assert_match "記做 IT 已測通過", response.body
  end

  test "client sees passed IT checks but not failed or unrecorded ones" do
    @checkout.update!(it_status: :pass, it_note: "喺測試站試過")
    @payment.update!(it_status: :fail, it_note: "內部備註：付款未修好")

    sign_in_as users(:two)
    get portal_project_path(@project)
    assert_response :success
    assert_match "IT 已測通過", response.body
    assert_match "喺測試站試過", response.body
    assert_no_match "內部備註：付款未修好", response.body
    assert_no_match "IT 測試未過", response.body
    assert_no_match "IT 未測", response.body
  end

  test "client sees the IT check beside each case while testing a round" do
    @checkout.update!(it_status: :pass, it_note: "喺測試站試過")
    sign_in_as users(:one)
    post admin_project_uat_rounds_path(@project)
    round = @project.uat_rounds.first
    sign_out

    sign_in_as users(:two)
    get portal_project_uat_round_path(@project, round)
    assert_response :success
    assert_match "IT 已測通過", response.body
    assert_match "喺測試站試過", response.body
  end

  test "client cannot record IT results" do
    sign_in_as users(:two)
    post mark_it_passed_admin_project_test_cases_path(@project)
    assert_response :forbidden
    assert @checkout.reload.it_untested?

    patch admin_project_test_case_path(@project, @checkout), params: { test_case: { it_status: "pass" } }
    assert_response :forbidden
    assert @checkout.reload.it_untested?
  end
end
