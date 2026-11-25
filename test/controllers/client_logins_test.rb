require "test_helper"

class ClientLoginsTest < ActionDispatch::IntegrationTest
  setup do
    @client = clients(:yoga)
    sign_in_as users(:one)
  end

  def shown_password = css_select("#new-password").first.text.strip

  test "admin opens a login and sees the password once" do
    get new_admin_client_user_path(@client)
    assert_response :success

    assert_difference -> { @client.users.count }, 1 do
      post admin_client_users_path(@client), params: { user: { email_address: "Owner@DemoYoga.example" } }
    end
    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_select "h1", "帳戶已建立"
    password = shown_password
    assert_match(/\A\w{4}-\w{4}-\w{4}\z/, password)
    assert_match password, css_select("#credentials-message").first.text
    assert_nil flash[:notice]

    user = User.find_by!(email_address: "owner@demoyoga.example")
    assert user.role_client?
    assert_equal @client, user.client
    assert user.authenticate(password)
  end

  test "an email that already has a login is rejected" do
    post admin_client_users_path(@client), params: { user: { email_address: users(:two).email_address } }
    assert_response :unprocessable_entity
    assert_select "#new-password", count: 0
  end

  test "resetting a password signs the client out everywhere" do
    client_user = users(:two)
    client_user.sessions.create!
    post reset_password_admin_user_path(client_user)
    assert_response :success
    assert_select "h1", "密碼已重設"
    assert client_user.reload.authenticate(shown_password)
    assert_not client_user.authenticate("password")
    assert_empty client_user.sessions
  end

  test "admin can delete a client login but not an admin" do
    assert_difference -> { User.count }, -1 do
      delete admin_user_path(users(:two))
    end
    assert_redirected_to admin_client_path(@client)

    delete admin_user_path(users(:one))
    assert_response :not_found
  end

  test "the client page lists its logins" do
    get admin_client_path(@client)
    assert_select "#logins-heading", "登入帳戶"
    assert_match users(:two).email_address, response.body
  end

  test "clients cannot manage logins" do
    sign_out
    sign_in_as users(:two)
    get new_admin_client_user_path(@client)
    assert_response :forbidden
    post reset_password_admin_user_path(users(:other_client))
    assert_response :forbidden
  end
end
