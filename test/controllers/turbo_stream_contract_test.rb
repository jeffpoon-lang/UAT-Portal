require "test_helper"

# Saving one result on the client's UAT page replaces three parts of the page
# by id (Portal::TestResultsController#update). A redesign that renames or
# drops one of those ids breaks live updates without any error, so pin them.
class TurboStreamContractTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:yoga_course)
    @round = @project.open_next_round!
    @result = @round.test_results.first
    sign_in_as users(:two)
  end

  test "the round page has every element the stream targets" do
    get portal_project_uat_round_path(@project, @round)
    assert_response :success
    assert_select "turbo-frame##{dom_id(@result)}"
    assert_select "#round-counts"
    assert_select "#round-submit"
  end

  test "saving a result replaces the result, the counts and the submit box" do
    patch portal_project_uat_round_test_result_path(@project, @round, @result),
          params: { test_result: { status: "pass" } }, as: :turbo_stream
    assert_response :success

    assert_select "turbo-stream[action=replace][target=#{dom_id(@result)}]" do
      assert_select "template turbo-frame##{dom_id(@result)}"
    end
    assert_select "turbo-stream[action=update][target=round-counts]"
    assert_select "turbo-stream[action=replace][target=round-submit]" do
      assert_select "template #round-submit"
    end
  end

  private
    def dom_id(record) = ActionView::RecordIdentifier.dom_id(record)
end
