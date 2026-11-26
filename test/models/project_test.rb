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

  test "a final sign-off outside the portal accepts UAT on its date" do
    project = projects(:yoga_course)
    project.external_sign_offs.create!(title: "內容驗收", signer_name: "陳大文", signed_on: "2026-10-20")
    assert_not project.reload.uat_accepted?

    project.external_sign_offs.create!(title: "最終驗收", signer_name: "陳大文", signed_on: "2026-11-01", final: true)
    project.reload
    assert project.uat_accepted?
    assert_equal Date.new(2026, 11, 1), project.uat_accepted_on
    assert_raises(UatRound::NotAllowed) { project.open_next_round! }
  end

  test "system links are grouped by kind in a fixed order" do
    project = projects(:yoga_course)
    project.system_links.create!(kind: "doc", label: "手冊")
    project.system_links.create!(kind: "site", label: "官網", position: 2)
    project.system_links.create!(kind: "site", label: "報名表", position: 1)
    groups = SystemLink.grouped(project.system_links.reload)
    assert_equal %w[site doc], groups.keys
    assert_equal %w[報名表 官網], groups["site"].map(&:label)
  end
end
