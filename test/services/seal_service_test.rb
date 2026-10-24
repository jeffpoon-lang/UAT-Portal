require "test_helper"

class SealServiceTest < ActiveSupport::TestCase
  test "returns a 64 char hex digest" do
    assert_match(/\A[0-9a-f]{64}\z/, SealService.digest({ round: 1 }))
  end

  test "key order does not change the digest" do
    a = SealService.digest({ round: 1, results: [ "TC-01 pass" ] })
    b = SealService.digest({ "results" => [ "TC-01 pass" ], "round" => 1 })
    assert_equal a, b
  end

  test "editing an earlier record breaks the chain" do
    d1 = SealService.digest({ round: 1, result: "pass" })
    d2 = SealService.digest({ round: 2, result: "pass" }, d1)

    tampered_d1 = SealService.digest({ round: 1, result: "fail" })
    assert_not_equal d2, SealService.digest({ round: 2, result: "pass" }, tampered_d1)
  end

  test "rejects a malformed previous digest" do
    assert_raises(SealService::Error) { SealService.digest({ round: 1 }, "not-a-digest") }
  end
end
