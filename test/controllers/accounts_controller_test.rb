require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account, login: 'testuser')
    @account_with_sponsors = create(:account, :with_many_sponsors, login: 'popular-user')
    @account_without_listing = create(:account, :without_sponsors_listing, login: 'private-user')
  end

  test "should get index" do
    get accounts_path
    assert_response :success
    assert_select 'title', /Maintainers/i
  end

  test "should get index with kind filter" do
    org_account = create(:account, :organization, login: 'testorg')
    
    get accounts_path(kind: 'organization')
    assert_response :success
  end

  test "should get index with sort and order parameters" do
    get accounts_path(sort: 'sponsors_count', order: 'desc')
    assert_response :success
    
    get accounts_path(sort: 'sponsors_count', order: 'asc')
    assert_response :success
  end

  test "should show account" do
    get account_path(@account)
    assert_response :success
    assert_select 'title', /testuser/i
  end

  test "should show account with mixed case login" do
    get account_path(@account.login.upcase)
    assert_response :redirect
    assert_redirected_to account_path(@account.login.downcase)
  end

  test "should return 404 for non-existent account" do
    get account_path('nonexistent-user')
    assert_response :not_found
  end

  test "should get sponsors page" do
    funder = create(:account, login: 'sponsor')
    create(:sponsorship, funder: funder, maintainer: @account)
    
    get sponsors_path
    assert_response :success
  end

  test "should get sponsors page with filters" do
    org_account = create(:account, :organization, login: 'sponsor-org')
    create(:sponsorship, funder: org_account, maintainer: @account)
    
    get sponsors_path(kind: 'organization')
    assert_response :success
  end

  test "should get sponsors page with sort parameters" do
    get sponsors_path(sort: 'active_sponsorships_count', order: 'desc')
    assert_response :success
  end

  test "should get charts page" do
    WebMock.stub_request(:get, "https://packages.ecosyste.ms/api/v1/packages/critical")
      .with(query: hash_including({}))
      .to_return(status: 200, body: "[]", headers: { 'Content-Type' => 'application/json' })
    
    get charts_path
    assert_response :success
    assert_select 'title', /Ecosyste.ms: Sponsors/
  end

  test "should get sponsor_charts page" do
    get sponsor_charts_path
    assert_response :success
    assert_select 'title', /Ecosyste.ms: Sponsors/
  end

  test "index should only show accounts with sponsors listing" do
    get accounts_path
    assert_response :success
    
    # Should include accounts with sponsors listing
    assert_select 'body', text: /#{@account.login}/
    assert_select 'body', text: /#{@account_with_sponsors.login}/
  end
end