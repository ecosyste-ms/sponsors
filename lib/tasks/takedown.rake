namespace :takedown do
  desc "Hide an account and remove its sponsorship data. LOGIN=username"
  task hide_user: :environment do
    login = ENV['LOGIN']
    abort "LOGIN is required" if login.blank?

    account = nil
    sponsorship_count = 0

    Account.transaction do
      account = Account.find_by('lower(login) = ?', login.downcase)
      account ||= Account.create!(login: login.downcase)

      sponsorships = Sponsorship.where(funder_id: account.id)
                                 .or(Sponsorship.where(maintainer_id: account.id))
      sponsorship_count = sponsorships.count

      account.update!(
        hidden: true,
        last_synced_at: nil,
        data: {},
        sponsor_profile: {},
        has_sponsors_listing: false,
        sponsors_count: 0,
        funded_count: 0,
        sponsorships_count: 0,
        active_sponsorships_count: 0,
        active_sponsors_count: 0,
        minimum_sponsorship_amount: nil
      )
      sponsorships.delete_all
    end

    puts "[sponsors] hidden account #{account.login}"
    puts "[sponsors] removed #{sponsorship_count} sponsorships for #{account.login}"
  end

  desc "Report what exists for an account. LOGIN=username"
  task report: :environment do
    login = ENV['LOGIN']
    abort "LOGIN is required" if login.blank?

    account = Account.find_by('lower(login) = ?', login.downcase)
    sponsorship_count = if account
      Sponsorship.where(funder_id: account.id)
                 .or(Sponsorship.where(maintainer_id: account.id))
                 .count
    else
      0
    end

    state = account ? (account.hidden? ? 'hidden' : 'visible') : 'none'
    puts "[sponsors] #{login}: account=#{state} sponsorships=#{sponsorship_count}"
  end
end
