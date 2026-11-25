require "test_helper"

class PasswordChangesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    sign_in_as @user
  end

  def change(current: "password", new: "a-new-password", confirm: new)
    patch password_change_path, params: { password_change: { current_password: current, password: new, password_confirmation: confirm } }
  end

  test "the account menu links to the page" do
    get portal_projects_path
    assert_select "a[href='#{edit_password_change_path}']", text: /改密碼/
    get edit_password_change_path
    assert_response :success
    assert_select "h1", "改密碼"
  end

  test "a wrong current password is rejected" do
    change(current: "wrong")
    assert_response :unprocessable_entity
    assert_select "[role=alert]", /現有密碼唔啱/
    assert @user.reload.authenticate("password")
  end

  test "a short or mismatched new password is rejected" do
    change(new: "short")
    assert_select "[role=alert]", /最少要 8 個字/
    change(confirm: "something-else")
    assert_select "[role=alert]", /兩次輸入嘅新密碼唔一樣/
    assert @user.reload.authenticate("password")
  end

  test "changing the password keeps this session and ends the others" do
    other = @user.sessions.create!
    change
    assert_redirected_to root_path
    assert @user.reload.authenticate("a-new-password")
    assert_not Session.exists?(other.id)
    assert Session.exists?(Current.session.id)
  end

  test "admins change theirs inside the admin layout" do
    sign_out
    sign_in_as users(:one)
    get edit_password_change_path
    assert_select ".app-sidebar"
  end
end
