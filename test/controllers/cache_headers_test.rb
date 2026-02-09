require 'test_helper'

class CacheHeadersTest < ActionDispatch::IntegrationTest
  test "HTML page sets cache headers with s-maxage" do
    get root_url
    assert_response :success

    cache_control = response.headers['Cache-Control']
    assert_match(/public/, cache_control)
    assert_match(/s-maxage=21600/, cache_control)
    assert_match(/max-age=300/, cache_control)
    assert_match(/stale-while-revalidate=21600/, cache_control)
    assert_match(/stale-if-error=86400/, cache_control)
  end

  test "account show page sets cache headers" do
    account = create(:account, login: 'cachetest')

    get account_url(account)
    assert_response :success

    cache_control = response.headers['Cache-Control']
    assert_match(/s-maxage=21600/, cache_control)
  end

  test "API endpoint sets shorter s-maxage" do
    get api_v1_accounts_url, as: :json
    assert_response :success

    cache_control = response.headers['Cache-Control']
    assert_match(/s-maxage=3600/, cache_control)
    assert_match(/max-age=300/, cache_control)
  end
end
