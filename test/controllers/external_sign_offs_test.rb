require "test_helper"

# UAT 喺系統以外簽咗：admin 記錄低，客戶喺 portal 睇到同下載文件
class ExternalSignOffsTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:yoga_course)
    @project.update!(phase: :maintenance)
  end

  def sign_off_params(**extra)
    { external_sign_off: { position: 1, scope: "final", title: "最終驗收", signer_name: "陳大文",
                           signed_on: "2026-11-01", countersigned_by: "Jeff Poon", final: "1",
                           statement: "本系統符合驗收要求，同意上線。",
                           document: fixture_file_upload("signed.pdf", "application/pdf") }.merge(extra) }
  end

  test "admin records a final sign-off and the project stops offering rounds" do
    sign_in_as users(:one)
    get new_admin_project_external_sign_off_path(@project)
    assert_response :success

    assert_difference -> { @project.external_sign_offs.count }, 1 do
      post admin_project_external_sign_offs_path(@project), params: sign_off_params
    end
    assert_redirected_to admin_project_path(@project, anchor: "external-sign-offs")
    sign_off = @project.external_sign_offs.last
    assert sign_off.document.attached?
    assert_equal "UAT 已喺系統外簽署驗收，唔使再開 round", @project.reload.cannot_open_round_reason

    get admin_project_path(@project)
    assert_select "#external-sign-offs", text: /最終驗收/
    assert_select ".callout", text: /UAT 已於 2026-11-01 喺系統外簽署驗收/
    assert_select "button", text: /開 Round/, count: 0
    assert_select "a[href=?]", document_admin_project_external_sign_off_path(@project, sign_off)

    get document_admin_project_external_sign_off_path(@project, sign_off)
    assert_response :success
    assert_equal "application/pdf", response.media_type
  end

  test "only PDF and image files are accepted" do
    sign_in_as users(:one)
    assert_no_difference -> { ExternalSignOff.count } do
      post admin_project_external_sign_offs_path(@project),
           params: sign_off_params(document: fixture_file_upload("notes.txt", "text/plain"))
    end
    assert_response :unprocessable_entity
    assert_select ".field-error", text: /只可以上載 PDF、PNG 或者 JPG/
  end

  test "a sign-off needs a title, signer and a date that has passed" do
    sign_in_as users(:one)
    post admin_project_external_sign_offs_path(@project),
         params: sign_off_params(title: "", signer_name: "", signed_on: Date.tomorrow.to_s)
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /標題 唔可以留空/
    assert_select "[role=alert]", text: /簽署日期 唔可以留空|唔可以係未來日子/
  end

  test "admin edits and deletes a sign-off" do
    sign_off = @project.external_sign_offs.create!(title: "內容驗收", signer_name: "陳大文", signed_on: "2026-10-20")
    sign_in_as users(:one)
    get edit_admin_project_external_sign_off_path(@project, sign_off)
    assert_response :success

    patch admin_project_external_sign_off_path(@project, sign_off), params: { external_sign_off: { scope: "A" } }
    assert_equal "A", sign_off.reload.scope

    delete admin_project_external_sign_off_path(@project, sign_off)
    assert_redirected_to admin_project_path(@project, anchor: "external-sign-offs")
    assert_not ExternalSignOff.exists?(sign_off.id)
  end

  test "the client sees the sign-offs and downloads their own document only" do
    sign_off = @project.external_sign_offs.create!(
      title: "最終驗收", scope: "final", signer_name: "陳大文", signed_on: "2026-11-01", final: true,
      statement: "本系統符合驗收要求，同意上線。",
      document: fixture_file_upload("signed.pdf", "application/pdf"))

    sign_in_as users(:two)
    get portal_project_path(@project)
    assert_select ".callout", text: /UAT 已於 2026-11-01 驗收完成/
    assert_select "h2", text: "驗收簽署"
    assert_match "本系統符合驗收要求，同意上線。", response.body
    assert_select "summary", text: /驗收清單/
    assert_select "a[href*='/admin/']", count: 0

    get document_portal_project_external_sign_off_path(@project, sign_off)
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_match "inline", response.headers["Content-Disposition"]
    assert_match "no-store", response.headers["Cache-Control"]
    sign_out

    sign_in_as users(:other_client)
    get document_portal_project_external_sign_off_path(@project, sign_off)
    assert_response :not_found
  end

  test "a non-final sign-off doesn't close UAT" do
    @project.update!(phase: :uat)
    @project.external_sign_offs.create!(title: "內容驗收", signer_name: "陳大文", signed_on: "2026-10-20")
    assert_nil @project.reload.cannot_open_round_reason
    assert_not @project.uat_accepted?
  end
end
