json.extract! sponsorship, :id, :status, :created_at, :updated_at
json.funder do
  json.partial! 'api/v1/accounts/account', account: sponsorship.funder
end

json.maintainer do
  json.partial! 'api/v1/accounts/account', account: sponsorship.maintainer
end