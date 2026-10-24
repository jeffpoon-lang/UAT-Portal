require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "phase order follows the delivery SOP" do
    assert_equal %w[requirement design development sat uat launch maintenance], Project::PHASES
    assert_equal 4, projects(:yoga_course).phase_index
    assert_equal "UAT", projects(:yoga_course).phase_label
  end

  test "next test case code continues the numbering" do
    assert_equal "TC-03", projects(:yoga_course).next_test_case_code
    assert_equal "TC-01", projects(:music_app).next_test_case_code
  end

  test "defaults to 3 UAT rounds" do
    assert_equal 3, Project.new.max_uat_rounds
  end

  test "requires at least one UAT round" do
    project = projects(:yoga_course)
    project.max_uat_rounds = 0
    assert_not project.valid?
  end
end
