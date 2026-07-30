require "test_helper"
require "rake"

class TakedownRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("takedown:hide_user")
    ENV.delete("LOGIN")
  end

  teardown do
    ENV.delete("LOGIN")
  end

  test "hide_user hides and scrubs an account" do
    account = create(
      :account,
      login: "target-user",
      funded_count: 2,
      last_synced_at: Time.current
    )
    other_account = create(:account, login: "other-user")
    create(:sponsorship, funder: account, maintainer: other_account)
    create(:sponsorship, funder: other_account, maintainer: account)
    ENV["LOGIN"] = account.login.upcase

    output, = capture_io { Rake::Task["takedown:hide_user"].execute }

    account.reload
    assert account.hidden?
    assert_nil account.last_synced_at
    assert_equal({}, account.data)
    assert_equal({}, account.sponsor_profile)
    assert_not account.has_sponsors_listing?
    assert_equal 0, account.sponsors_count
    assert_equal 0, account.funded_count
    assert_equal 0, account.sponsorships_count
    assert_equal 0, account.active_sponsorships_count
    assert_equal 0, account.active_sponsors_count
    assert_nil account.minimum_sponsorship_amount
    assert_equal 0, Sponsorship.where(funder: account).or(Sponsorship.where(maintainer: account)).count
    assert_includes output, "[sponsors] hidden account #{account.login}"
    assert_includes output, "[sponsors] removed 2 sponsorships"
  end

  test "hide_user creates a hidden tombstone for an unknown account" do
    ENV["LOGIN"] = "Missing-User"

    capture_io { Rake::Task["takedown:hide_user"].execute }

    account = Account.find_by(login: "missing-user")
    assert account.hidden?
  end

  test "hide_user aborts without LOGIN" do
    assert_raises(SystemExit) do
      capture_io { Rake::Task["takedown:hide_user"].execute }
    end
  end

  test "report describes the hidden account" do
    account = create(:account, :hidden, login: "hidden-user")
    ENV["LOGIN"] = account.login

    output, = capture_io { Rake::Task["takedown:report"].execute }

    assert_includes output, "[sponsors] hidden-user: account=hidden sponsorships=0"
  end
end
