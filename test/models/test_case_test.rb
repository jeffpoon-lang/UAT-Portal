require "test_helper"

class TestCaseTest < ActiveSupport::TestCase
  setup { @tc = test_cases(:checkout) }

  test "starts with no IT result" do
    assert @tc.it_untested?
    assert_not @tc.it_checked?
    assert_nil @tc.it_tested_on
  end

  test "recording an IT result without a date uses today" do
    @tc.update!(it_status: :pass)
    assert_equal Date.current, @tc.it_tested_on
    assert @tc.it_checked?
    assert_equal "IT 已測通過", @tc.it_status_label
  end

  test "keeps the date given" do
    @tc.update!(it_status: :fail, it_tested_on: Date.current - 3)
    assert_equal Date.current - 3, @tc.it_tested_on
  end

  test "going back to untested clears the date" do
    @tc.update!(it_status: :pass, it_tested_on: Date.current - 1)
    @tc.update!(it_status: :untested)
    assert_nil @tc.it_tested_on
  end

  test "IT test date cannot be in the future" do
    @tc.assign_attributes(it_status: :pass, it_tested_on: Date.current + 1)
    assert_not @tc.valid?
    assert_includes @tc.errors[:it_tested_on], "唔可以係未來日子"
  end

  test "marking untested cases as passed leaves recorded results alone" do
    project = @tc.project
    failed = test_cases(:payment)
    failed.update!(it_status: :fail, it_tested_on: Date.current - 2, it_note: "付款頁出錯")

    changed = project.mark_untested_cases_it_passed!

    assert_equal project.test_cases.count - 1, changed
    assert failed.reload.it_fail?
    assert_equal Date.current - 2, failed.it_tested_on
    assert @tc.reload.it_pass?
    assert_equal Date.current, @tc.it_tested_on
    assert_equal 0, project.mark_untested_cases_it_passed!
  end
end
