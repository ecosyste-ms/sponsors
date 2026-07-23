require "test_helper"

class SponsorshipGraphTest < ActiveSupport::TestCase
  def account(login)
    create(:account, login: login)
  end

  test "mutual_pairs finds accounts that sponsor each other" do
    alice = account("alice")
    bob = account("bob")
    carol = account("carol")
    create(:sponsorship, funder: alice, maintainer: bob)
    create(:sponsorship, funder: bob, maintainer: alice)
    create(:sponsorship, funder: alice, maintainer: carol)

    assert_equal [["alice", "bob"]], SponsorshipGraph.mutual_pairs
    assert_equal 1, SponsorshipGraph.mutual_pair_count
  end

  test "mutual_pairs ignores pairs with an inactive side unless active_only is false" do
    alice = account("alice")
    bob = account("bob")
    create(:sponsorship, funder: alice, maintainer: bob)
    create(:sponsorship, :inactive, funder: bob, maintainer: alice)

    assert_equal [], SponsorshipGraph.mutual_pairs
    assert_equal 0, SponsorshipGraph.mutual_pair_count
    assert_equal [["alice", "bob"]], SponsorshipGraph.mutual_pairs(active_only: false)
    assert_equal 1, SponsorshipGraph.mutual_pair_count(active_only: false)
  end

  test "triangles finds three accounts sponsoring in a circle" do
    alice = account("alice")
    bob = account("bob")
    carol = account("carol")
    create(:sponsorship, funder: alice, maintainer: bob)
    create(:sponsorship, funder: bob, maintainer: carol)
    create(:sponsorship, funder: carol, maintainer: alice)

    assert_equal [["alice", "bob", "carol"]], SponsorshipGraph.triangles
  end

  test "triangles excludes circles with an inactive edge" do
    alice = account("alice")
    bob = account("bob")
    carol = account("carol")
    create(:sponsorship, funder: alice, maintainer: bob)
    create(:sponsorship, funder: bob, maintainer: carol)
    create(:sponsorship, :inactive, funder: carol, maintainer: alice)

    assert_equal [], SponsorshipGraph.triangles
  end

  test "strongly_connected_components groups accounts whose sponsorships form cycles" do
    alice = account("alice")
    bob = account("bob")
    carol = account("carol")
    dave = account("dave")
    eve = account("eve")
    # cycle of three
    create(:sponsorship, funder: alice, maintainer: bob)
    create(:sponsorship, funder: bob, maintainer: carol)
    create(:sponsorship, funder: carol, maintainer: alice)
    # mutual pair
    create(:sponsorship, funder: dave, maintainer: eve)
    create(:sponsorship, funder: eve, maintainer: dave)
    # one-way edge out of the cycle
    frank = account("frank")
    create(:sponsorship, funder: alice, maintainer: frank)

    assert_equal [["alice", "bob", "carol"], ["dave", "eve"]], SponsorshipGraph.strongly_connected_components
  end

  test "strongly_connected_components merges cycles that share accounts" do
    alice = account("alice")
    bob = account("bob")
    carol = account("carol")
    create(:sponsorship, funder: alice, maintainer: bob)
    create(:sponsorship, funder: bob, maintainer: alice)
    create(:sponsorship, funder: bob, maintainer: carol)
    create(:sponsorship, funder: carol, maintainer: bob)

    assert_equal [["alice", "bob", "carol"]], SponsorshipGraph.strongly_connected_components
  end

  test "strongly_connected_components ignores inactive cycles" do
    alice = account("alice")
    bob = account("bob")
    create(:sponsorship, :inactive, funder: alice, maintainer: bob)
    create(:sponsorship, :inactive, funder: bob, maintainer: alice)

    assert_equal [], SponsorshipGraph.strongly_connected_components
  end
end
