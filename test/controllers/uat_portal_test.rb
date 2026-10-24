require "test_helper"

class UatPortalTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:yoga_course)
  end

  test "full UAT journey: fail, fix, pass, sign off, verify" do
    # 你開 round 1
    sign_in_as users(:one)
    post admin_project_uat_rounds_path(@project)
    round1 = @project.uat_rounds.first
    assert_redirected_to admin_project_uat_round_path(@project, round1)
    sign_out

    # 客測試：一條 pass，一條 fail 連截圖
    sign_in_as users(:two)
    get portal_project_path(@project)
    assert_match "開始 UAT Round 1", response.body

    pass, fail = round1.test_results.to_a
    patch portal_project_uat_round_test_result_path(@project, round1, pass),
          params: { test_result: { status: "pass" } }, as: :turbo_stream
    assert_response :success

    patch portal_project_uat_round_test_result_path(@project, round1, fail),
          params: { test_result: { status: "fail", comment: "冇收到 email",
                                   screenshots: [ fixture_file_upload("screenshot.png", "image/png") ] } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "提交，等 IT 修正", response.body
    assert_equal 1, fail.reload.screenshots.count

    post request_changes_portal_project_uat_round_path(@project, round1)
    assert round1.reload.status_changes_requested?
    sign_out

    # 你改好，開 round 2
    sign_in_as users(:one)
    post admin_project_uat_rounds_path(@project)
    round2 = @project.uat_rounds.last
    assert_equal 2, round2.number
    sign_out

    # 客全部 pass 之後簽署
    sign_in_as users(:two)
    round2.test_results.each do |r|
      patch portal_project_uat_round_test_result_path(@project, round2, r), params: { test_result: { status: "pass" } }
    end
    post sign_off_portal_project_uat_round_path(@project, round2), params: { signer_name: "Demo Client", confirm: "1" }
    sign_off = SignOff.last
    assert_redirected_to portal_sign_off_path(sign_off)
    follow_redirect!
    assert_match "UAT-DEMOYOGA-001", response.body
    sign_out

    # 你驗證成條 chain
    sign_in_as users(:one)
    post verify_admin_sign_offs_path
    follow_redirect!
    assert_match "驗證通過：1 條", response.body
  end

  test "sign-off needs the confirmation box" do
    round = @project.open_next_round!
    round.test_results.each { |r| r.update!(status: :pass) }
    sign_in_as users(:two)
    post sign_off_portal_project_uat_round_path(@project, round), params: { signer_name: "Demo Client" }
    assert_redirected_to portal_project_uat_round_path(@project, round)
    assert_equal 0, SignOff.count
  end

  test "admin cannot sign on the client's behalf" do
    round = @project.open_next_round!
    round.test_results.each { |r| r.update!(status: :pass) }
    sign_in_as users(:one)
    post sign_off_portal_project_uat_round_path(@project, round), params: { signer_name: "Jeff", confirm: "1" }
    assert_response :forbidden
  end

  test "non-image screenshots are rejected" do
    round = @project.open_next_round!
    result = round.test_results.first
    sign_in_as users(:two)
    patch portal_project_uat_round_test_result_path(@project, round, result),
          params: { test_result: { status: "fail", comment: "x", screenshots: [ fixture_file_upload("notes.txt", "text/plain") ] } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :unprocessable_entity
    assert_equal 0, result.reload.screenshots.count
  end

  test "another client cannot see this round" do
    round = @project.open_next_round!
    sign_in_as users(:other_client)
    get portal_project_uat_round_path(@project, round)
    assert_response :not_found
  end

  test "verify reports tampering to the admin" do
    round = @project.open_next_round!
    round.test_results.each { |r| r.update!(status: :pass) }
    s = SignOff.sign!(round: round, user: users(:two), signer_name: "Demo Client")
    SignOff.where(id: s.id).update_all(signer_name: "x", payload_json: s.payload_json.sub("Demo Client", "Someone"))

    sign_in_as users(:one)
    post verify_admin_sign_offs_path
    follow_redirect!
    assert_match "驗證失敗：第 1 條", response.body
  end

  test "admin pages for UAT render" do
    round = @project.open_next_round!
    sign_in_as users(:one)
    [ admin_project_path(@project), admin_project_uat_round_path(@project, round),
      new_admin_project_change_request_path(@project), admin_sign_offs_path ].each do |path|
      get path
      assert_response :success, path
    end
  end
end
