namespace :accounts do
  task sync_least_recent: :environment do
    Account.sync_least_recently_synced
  end

  task import_from_repos: :environment do
    Account.import_from_repos
  end
end