require "test_helper"

# 系統資料頁：admin 記低網址同帳戶，客戶喺 portal 睇
class SystemLinksTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:yoga_course)
    @project.update!(phase: :maintenance)
  end

  test "admin adds a link and support notes, and the client sees them" do
    sign_in_as users(:one)
    get new_admin_project_system_link_path(@project, kind: "admin")
    assert_response :success
    assert_select "select#system_link_kind option[selected][value=admin]"

    post admin_project_system_links_path(@project), params: { system_link: {
      kind: "admin", label: "報名 Admin", url: "https://admin.demoyoga.example/login",
      account_owner: "Demo Yoga（hello@demoyoga.example）", note: "連續 5 次錯密碼會鎖 15 分鐘" } }
    assert_redirected_to admin_project_path(@project, anchor: "system-links")
    patch admin_project_path(@project), params: { project: { support_notes: "緊急：WhatsApp 5123 4567" } }

    get admin_project_path(@project)
    assert_select "#system-links", text: /報名 Admin/
    sign_out

    sign_in_as users(:two)
    get portal_project_path(@project)
    assert_select "a[href=?]", portal_project_system_path(@project), text: /系統資料/

    get portal_project_system_path(@project)
    assert_response :success
    assert_select "h2", text: /管理後台/
    assert_select "a[href='https://admin.demoyoga.example/login'][target=_blank][rel~=noopener]", text: /報名 Admin/
    assert_match "Demo Yoga（hello@demoyoga.example）", response.body
    assert_match "連續 5 次錯密碼會鎖 15 分鐘", response.body
    assert_match "緊急：WhatsApp 5123 4567", response.body
  end

  test "only web addresses are allowed" do
    sign_in_as users(:one)
    assert_no_difference -> { SystemLink.count } do
      post admin_project_system_links_path(@project), params: { system_link: { kind: "site", label: "壞連結", url: "javascript:alert(1)" } }
    end
    assert_response :unprocessable_entity
    assert_select ".field-error", text: /要係 http:\/\/ 或者 https:\/\/ 開頭嘅網址/
  end

  test "admin edits and deletes a link" do
    link = @project.system_links.create!(kind: "site", label: "官網", url: "https://demoyoga.example")
    sign_in_as users(:one)
    get edit_admin_project_system_link_path(@project, link)
    assert_response :success
    patch admin_project_system_link_path(@project, link), params: { system_link: { label: "官方網站" } }
    assert_equal "官方網站", link.reload.label
    delete admin_project_system_link_path(@project, link)
    assert_not SystemLink.exists?(link.id)
  end

  test "an empty system page says so, and other clients can't open it" do
    sign_in_as users(:two)
    get portal_project_system_path(@project)
    assert_response :success
    assert_select ".empty", text: /未有系統資料/
    sign_out

    sign_in_as users(:other_client)
    get portal_project_system_path(@project)
    assert_response :not_found
  end
end
