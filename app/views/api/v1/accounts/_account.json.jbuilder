json.extract! account, :id, :login, :data, :created_at, :updated_at, :last_synced_at, :sponsors_count, :sponsorships_count, :active_sponsorships_count, :sponsor_profile

json.url account_url(account.login)
json.api_url api_v1_account_url(account.login)
json.html_url account.html_url
json.sponsors_url account.sponsors_url