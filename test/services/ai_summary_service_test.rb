require "test_helper"

class AiSummaryServiceTest < ActiveSupport::TestCase
  setup do
    @round = projects(:yoga_course).open_next_round!
    a, b = @round.test_results.to_a
    a.update!(status: :fail, comment: "冇收到 email")
    b.update!(status: :fail, comment: "想加 PayPal 付款")
    @round.test_results.reset
  end

  def fake_openai(content)
    calls = []
    http = ->(body) { calls << body; { "choices" => [ { "message" => { "content" => content } } ] } }
    [ http, calls ]
  end

  test "classifies failing results and stores the summary" do
    http, calls = fake_openai(JSON.generate(
      overall: "一個 bug，一個新需求",
      items: [
        { code: "TC-01", category: "bug", summary: "冇確認 email", reason: "預期要收到 email" },
        { code: "TC-02", category: "change_request", summary: "加 PayPal", reason: "原本只有 Stripe" }
      ]
    ))
    summary = AiSummaryService.call(@round, http: http, api_key: "test-key")

    assert_equal %w[bug change_request], summary["items"].map { |i| i["category"] }
    assert_equal "一個 bug，一個新需求", @round.reload.ai_summary["overall"]
    assert_not_nil @round.ai_summarised_at

    sent = calls.first
    assert_equal "json_object", sent[:response_format][:type]
    assert_includes sent[:messages].last[:content], "想加 PayPal 付款"
  end

  test "drops unknown codes and bad categories from the model output" do
    http, = fake_openai(JSON.generate(
      overall: "ok",
      items: [
        { code: "TC-01", category: "delete everything", summary: "x", reason: "y" },
        { code: "TC-99", category: "bug", summary: "唔存在", reason: "z" },
        { code: "TC-01", category: "bug", summary: "重複", reason: "z" }
      ]
    ))
    summary = AiSummaryService.call(@round, http: http, api_key: "test-key")
    assert_equal [ "TC-01" ], summary["items"].map { |i| i["code"] }
    assert_equal "unclear", summary["items"].first["category"]
  end

  test "rejects output that is not JSON" do
    http, = fake_openai("Sure! Here is your summary")
    assert_raises(AiSummaryService::Error) { AiSummaryService.call(@round, http: http, api_key: "test-key") }
    assert_nil @round.reload.ai_summary
  end

  test "needs an API key" do
    error = assert_raises(AiSummaryService::Error) { AiSummaryService.call(@round, api_key: nil) }
    assert_match "OPENAI_API_KEY", error.message
  end

  test "skips the API when everything passed" do
    @round.test_results.each { |r| r.update!(status: :pass, comment: nil) }
    @round.test_results.reset
    http = ->(_) { flunk "唔應該叫 API" }
    summary = AiSummaryService.call(@round, http: http, api_key: "test-key")
    assert_empty summary["items"]
  end
end
