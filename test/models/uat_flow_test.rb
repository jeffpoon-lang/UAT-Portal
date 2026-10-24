require "test_helper"

class UatFlowTest < ActiveSupport::TestCase
  setup do
    @project = projects(:yoga_course)
    @client_user = users(:two)
  end

  def answer_all(round, status)
    round.test_results.each { |r| r.update!(status: status, comment: (status == "pass" ? nil : "有問題")) }
    round.test_results.reset
  end

  test "opening a round creates a result for every test case" do
    round = @project.open_next_round!
    assert_equal 1, round.number
    assert_equal 2, round.test_results.count
    assert round.test_results.all?(&:status_pending?)
  end

  test "only one open round at a time" do
    @project.open_next_round!
    error = assert_raises(UatRound::NotAllowed) { @project.reload.open_next_round! }
    assert_match "未完", error.message
  end

  test "failing a test needs a comment" do
    result = @project.open_next_round!.test_results.first
    result.status = :fail
    assert_not result.valid?
    result.comment = "撳咗冇反應"
    assert result.valid?
  end

  test "rounds are capped by the contract until a CR is approved" do
    @project.update!(max_uat_rounds: 1)
    round = @project.open_next_round!
    answer_all(round, "fail")
    round.request_changes!

    assert_match "CR", @project.reload.cannot_open_round_reason

    cr = @project.change_requests.create!(description: "加改 checkout 流程", extra_rounds: 1, quote_hkd: 1500)
    assert_equal "CR-DEMOYOGA-001", cr.doc_number
    assert_not_nil @project.reload.cannot_open_round_reason, "未批核嘅 CR 唔應該加 round"

    cr.update!(status: :approved)
    assert_nil @project.reload.cannot_open_round_reason
    assert_equal 2, @project.open_next_round!.number
  end

  test "cannot request changes when everything passed" do
    round = @project.open_next_round!
    answer_all(round, "pass")
    assert_raises(UatRound::NotAllowed) { round.request_changes! }
  end

  test "sign-off needs every test to pass" do
    round = @project.open_next_round!
    answer_all(round, "fail")
    assert_raises(UatRound::NotAllowed) { SignOff.sign!(round: round, user: @client_user, signer_name: "Demo Client") }
  end

  test "sign-off locks the round, numbers the document and moves to Launch" do
    round = @project.open_next_round!
    answer_all(round, "pass")
    sign_off = SignOff.sign!(round: round, user: @client_user, signer_name: "Demo Client")

    assert_equal "UAT-DEMOYOGA-001", sign_off.doc_number
    assert_equal SealService::GENESIS, sign_off.prev_digest
    assert_match(/\A[0-9a-f]{64}\z/, sign_off.digest)
    assert round.reload.status_signed_off?
    assert @project.reload.phase_launch?
    assert_equal %w[TC-01 TC-02], sign_off.payload["results"].map { |r| r["code"] }

    assert sign_off.readonly?
    assert_raises(ActiveRecord::ReadOnlyRecord) { sign_off.update!(signer_name: "Someone else") }

    result = round.test_results.first
    result.status = :fail
    result.comment = "改結果"
    assert_not result.save, "簽咗之後唔應該改到結果"
  end

  test "sign-offs chain together and tampering is detected" do
    first = sign_round(@project)
    other = Project.create!(client: clients(:music), name: "Music app UAT")
    other.test_cases.create!(code: "TC-01", title: "播到歌")
    second = sign_round(other)

    assert_equal first.digest, second.prev_digest
    assert SignOff.verify_chain.ok?
    assert_equal 2, SignOff.verify_chain.count

    # 有人直接改 DB 入面嘅內容
    SignOff.where(id: first.id).update_all(payload_json: first.payload_json.sub("pass", "fail"))
    result = SignOff.verify_chain
    assert_not result.ok?
    assert_equal 1, result.broken_index
    assert_equal "digest_mismatch", result.reason
  end

  test "deleting a sign-off breaks the chain" do
    sign_round(@project)
    other = Project.create!(client: clients(:music), name: "Music app UAT")
    other.test_cases.create!(code: "TC-01", title: "播到歌")
    sign_round(other)

    SignOff.order(:id).first.then { |s| SignOff.where(id: s.id).delete_all }
    result = SignOff.verify_chain
    assert_not result.ok?
    assert_equal "prev_mismatch", result.reason
  end

  private
    def sign_round(project)
      round = project.open_next_round!
      answer_all(round, "pass")
      user = User.find_by(client_id: project.client_id) || @client_user
      SignOff.sign!(round: round, user: user, signer_name: "Demo Client")
    end
end
