require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "a client user must belong to a client" do
    user = User.new(email_address: "x@example.com", password: "secret123", role: :client)
    assert_not user.valid?
  end
end
