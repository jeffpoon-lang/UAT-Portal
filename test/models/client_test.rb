require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "code is upcased and must be short letters or digits" do
    client = Client.new(name: "X", code: " ahyu ")
    assert client.valid?
    assert_equal "AHYU", client.code

    client.code = "BAD-CODE"
    assert_not client.valid?
  end
end
