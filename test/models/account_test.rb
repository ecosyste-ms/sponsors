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
  test "hidden accounts are not imported again" do
    account = create(:account, :hidden, login: "hidden-user")

    assert_nil Account.attempt_import_from_repos(account.login)
    assert_not_requested :get, account.repos_api_url
  end

  test "hidden accounts are not queued or synced" do
    account = create(:account, :hidden)
    account.define_singleton_method(:sync) { raise "hidden account was synced" }

    assert_nil account.sync_async
    assert_nil account.sync_all
  end

  test "sponsorship sync ignores a hidden sponsor" do
    account = create(:account, login: "maintainer")
    hidden_sponsor = create(:account, :hidden, login: "hidden-sponsor")
    account.define_singleton_method(:fetch_all_sponsors) do |filter: nil|
      filter == "active" ? [hidden_sponsor.login] : []
    end

    assert_no_difference "Sponsorship.count" do
      account.sync_sponsorships
    end
  end

  test "import from repos leaves hidden accounts unchanged" do
    account = create(:account, :hidden, login: "hidden-user")
    stub_request(:get, "https://repos.ecosyste.ms/api/v1/hosts/GitHub/owners/sponsors_logins")
      .to_return(status: 200, body: [account.login].to_json)

    Account.import_from_repos

    assert_equal 1, Account.where("lower(login) = ?", account.login).count
    assert account.reload.hidden?
  end
end
