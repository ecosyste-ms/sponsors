require "test_helper"

class AccountMutualTest < ActiveSupport::TestCase
  test "mutual_accounts returns accounts with active sponsorships both ways" do
    alice = create(:account, login: "alice")
    bob = create(:account, login: "bob")
    carol = create(:account, login: "carol")
    dave = create(:account, login: "dave")
    create(:sponsorship, funder: alice, maintainer: bob)
    create(:sponsorship, funder: bob, maintainer: alice)
    create(:sponsorship, funder: alice, maintainer: carol)
    create(:sponsorship, funder: dave, maintainer: alice)
    create(:sponsorship, :inactive, funder: alice, maintainer: dave)

    assert_equal [bob], alice.mutual_accounts.to_a
  end
end

class AccountTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
