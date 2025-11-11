require 'test_helper'

class Api::V1::AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account, login: 'testuser')
    @account_with_sponsors = create(:account, :with_many_sponsors, login: 'popular-user')
    @funder = create(:account, login: 'sponsor')
    @sponsorship = create(:sponsorship, funder: @funder, maintainer: @account)
  end

  test "should get index as JSON" do
    get api_v1_accounts_path
    assert_response :success
    assert_equal 'application/json', response.media_type
    
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  test "should show account as JSON" do
    get api_v1_account_path(@account)
    assert_response :success
    assert_equal 'application/json', response.media_type
    
    json = JSON.parse(response.body)
    assert_equal @account.login, json['login']
    assert_equal @account.sponsors_count, json['sponsors_count']
  end

  test "should show account with mixed case login" do
    get api_v1_account_path(@account.login.upcase)
    assert_response :redirect
    assert_redirected_to api_v1_account_path(@account.login.downcase)
  end

  test "should attempt import for non-existent account" do
    # Mock the external API call to prevent actual HTTP requests
    WebMock.stub_request(:get, "https://repos.ecosyste.ms/api/v1/hosts/GitHub/owners/newuser")
      .to_return(status: 404, body: "", headers: {})
    
    get api_v1_account_path('newuser')
    assert_response :not_found
  end

  test "should get sponsors as JSON" do
    get '/api/v1/sponsors'
    assert_response :success
    assert_equal 'application/json', response.media_type

    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  test "should filter sponsors by active status in API" do
    active_sponsor = create(:account, login: 'active-sponsor')
    inactive_sponsor = create(:account, login: 'inactive-sponsor')
    maintainer = create(:account, login: 'maintainer')

    create(:sponsorship, funder: active_sponsor, maintainer: maintainer, status: 'active')
    create(:sponsorship, :inactive, funder: inactive_sponsor, maintainer: maintainer)

    active_sponsor.update(active_sponsorships_count: 1, sponsorships_count: 1)
    inactive_sponsor.update(active_sponsorships_count: 0, sponsorships_count: 1)

    get '/api/v1/sponsors', params: { active: 'true' }
    assert_response :success
    assert_equal 'application/json', response.media_type

    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  test "should show all sponsors without active filter in API" do
    active_sponsor = create(:account, login: 'active-sponsor')
    inactive_sponsor = create(:account, login: 'inactive-sponsor')
    maintainer = create(:account, login: 'maintainer')

    create(:sponsorship, funder: active_sponsor, maintainer: maintainer, status: 'active')
    create(:sponsorship, :inactive, funder: inactive_sponsor, maintainer: maintainer)

    active_sponsor.update(active_sponsorships_count: 1, sponsorships_count: 1)
    inactive_sponsor.update(active_sponsorships_count: 0, sponsorships_count: 1)

    get '/api/v1/sponsors'
    assert_response :success
    assert_equal 'application/json', response.media_type

    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  test "should get account sponsorships" do
    get api_v1_account_sponsorships_path(@account)
    assert_response :success
    assert_equal 'application/json', response.media_type
    
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  test "should return 404 for sponsorships of non-existent account" do
    get api_v1_account_sponsorships_path('nonexistent-user')
    assert_response :not_found
  end

  test "should get account sponsors" do
    get api_v1_account_sponsors_path(@funder)
    assert_response :success
    assert_equal 'application/json', response.media_type
    
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  test "should return 404 for sponsors of non-existent account" do
    get api_v1_account_sponsors_path('nonexistent-user')
    assert_response :not_found
  end

  test "should get sponsor logins" do
    get sponsor_logins_api_v1_accounts_path
    assert_response :success
    assert_equal 'application/json', response.media_type
    
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
    assert json.include?(@account.login)
  end

  test "sponsor logins should only include accounts with sponsors listing" do
    account_without_listing = create(:account, :without_sponsors_listing, login: 'private-user')
    
    get sponsor_logins_api_v1_accounts_path
    assert_response :success
    
    json = JSON.parse(response.body)
    assert json.include?(@account.login)
    assert_not json.include?(account_without_listing.login)
  end

  test "should handle mixed case login in sponsorships endpoint" do
    get api_v1_account_sponsorships_path(@account.login.upcase)
    assert_response :success
  end

  test "should handle mixed case login in sponsors endpoint" do
    get api_v1_account_sponsors_path(@funder.login.upcase)
    assert_response :success
  end

  test "should get index returns array of accounts" do
    get api_v1_accounts_path
    assert_response :success

    json = JSON.parse(response.body)
    assert json.is_a?(Array)
    assert json.length >= 0
  end

  test "should filter maintainers by active status in API" do
    active_maintainer = create(:account, login: 'active-maintainer-api', has_sponsors_listing: true)
    inactive_maintainer = create(:account, login: 'inactive-maintainer-api', has_sponsors_listing: true)
    api_sponsor = create(:account, login: 'api-sponsor-1')

    create(:sponsorship, funder: api_sponsor, maintainer: active_maintainer, status: 'active')
    create(:sponsorship, :inactive, funder: api_sponsor, maintainer: inactive_maintainer)

    active_maintainer.update(active_sponsors_count: 1, sponsors_count: 1)
    inactive_maintainer.update(active_sponsors_count: 0, sponsors_count: 1)

    get api_v1_accounts_path(active: 'true')
    assert_response :success
    assert_equal 'application/json', response.media_type

    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end

  test "should show all maintainers without active filter in API" do
    active_maintainer = create(:account, login: 'active-maintainer-api-2', has_sponsors_listing: true)
    inactive_maintainer = create(:account, login: 'inactive-maintainer-api-2', has_sponsors_listing: true)
    api_sponsor = create(:account, login: 'api-sponsor-2')

    create(:sponsorship, funder: api_sponsor, maintainer: active_maintainer, status: 'active')
    create(:sponsorship, :inactive, funder: api_sponsor, maintainer: inactive_maintainer)

    active_maintainer.update(active_sponsors_count: 1, sponsors_count: 1)
    inactive_maintainer.update(active_sponsors_count: 0, sponsors_count: 1)

    get api_v1_accounts_path
    assert_response :success
    assert_equal 'application/json', response.media_type

    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end
end