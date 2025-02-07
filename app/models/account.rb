class Account < ApplicationRecord
  validates :login, presence: true

  has_many :sponsorships_as_funder, class_name: "Sponsorship", foreign_key: :funder_id
  has_many :sponsorships_as_maintainer, class_name: "Sponsorship", foreign_key: :maintainer_id

  has_many :maintained_accounts, through: :sponsorships_as_funder, source: :maintainer
  has_many :funder_accounts, through: :sponsorships_as_maintainer, source: :funder

  scope :has_sponsors_listing, -> { where(has_sponsors_listing: true) }
  scope :has_sponsors_profile, -> { where('length(sponsor_profile::text) > 2') }
  scope :has_active_sponsorships, -> { where('active_sponsorships_count > 0') }
  
  scope :with_sponsors, -> { where('sponsors_count > 0') }
  scope :with_sponsorships, -> { where('sponsorships_count > 0') }

  scope :active_funders, -> { where('active_sponsorships_count > 0') }

  scope :kind, ->(kind) { where("data->>'kind' = ?", kind) }
  scope :users, -> { where("data->>'kind' = ?", 'user') }
  scope :organizations, -> { where("data->>'kind' = ?", 'organization') }

  def self.sync_least_recently_synced
    Account.where(last_synced_at: nil).or(Account.where("last_synced_at < ?", 1.day.ago)).order('last_synced_at asc nulls first').limit(1000).each do |account|
      account.sync_async
    end
  end

  def to_s
    login
  end

  def to_param
    login
  end

  def set_sponsors_count
    self.sponsors_count = sponsorships_as_maintainer.count > total_sponsors ? sponsorships_as_maintainer.count : total_sponsors
    self.sponsorships_count = sponsorships_as_funder.count
    self.active_sponsorships_count = sponsorships_as_funder.active.count
    self.active_sponsors_count = sponsorships_as_maintainer.active.count > current_sponsors ? sponsorships_as_maintainer.active.count : current_sponsors
  end

  def self.import_from_repos
    url = 'https://repos.ecosyste.ms/api/v1/hosts/GitHub/owners/sponsors_logins'

    resp = Faraday.get(url)

    return unless resp.status == 200

    logins = JSON.parse(resp.body)

    logins.map(&:downcase).each do |login|
      account = Account.find_by(login: login)

      if account.nil?
        account = Account.create(login: login, has_sponsors_listing: true)
        account.sync_async
      end

    end
  end

  def ping_repos
    Faraday.get(repos_api_url + '/ping') 
  rescue => e
    puts "Error pinging repos for #{login}"
    puts e
  end

  def repos_api_url
    "https://repos.ecosyste.ms/api/v1/hosts/GitHub/owners/#{login}"
  end

  def html_url
    "https://github.com/#{login}"
  end

  def sponsors_url
    "https://github.com/sponsors/#{login}"
  end

  def avatar_url
    "https://avatars.githubusercontent.com/#{login}"
  end

  def sync_all
    sync

    scrape_sponsored_page

    sync_sponsorships

    sync_funder
    
    sync_funder_html

    ping_repos

    set_sponsors_count

    update last_synced_at: Time.now
  end

  def sync
    resp = Faraday.get(repos_api_url)

    return unless resp.status == 200

    data = JSON.parse(resp.body)

    update(
      data: data,
      has_sponsors_listing: data['metadata']['has_sponsors_listing']  
    )
  rescue => e
    puts "Error syncing account #{login}"
    puts e
  end

  def sync_async
    AccountWorker.perform_async(id)
  end

  def scrape_sponsored_page
    return unless has_sponsors_listing?
    resp = Faraday.get(sponsors_url)

    return unless resp.status == 200

    doc = Nokogiri::HTML(resp.body)
    
    bio = doc.at_css('.markdown-body').text.strip
  
    featured_works = doc.css('.d-flex.col-12.col-lg-6.float-left.mb-3').map do |work|
      {
        title: work.at_css('a.color-fg-inherit.text-bold').text.strip,
        description: work.at_css('p').text.strip,
        url: "https://github.com/" + work.at_css('a.color-fg-inherit.text-bold')['href'],
        language: work.at_css('span[itemprop="programmingLanguage"]')&.text&.strip,
        stars: work.at_css('a.no-wrap.Link.Link--muted.f6')&.text&.gsub(',', '')&.strip
      }
    end

    c4 = doc.at('h4:contains("Current sponsors")')
    current_sponsors = c4&.at('span.Counter')&.text&.delete(',')&.to_i  || 0
    
    p4 = doc.at('h4:contains("Past sponsors")') || doc.at('h5:contains("Past sponsors")')
    past_sponsors = p4&.at('span.Counter')&.text&.delete(',')&.to_i  || 0

    if current_sponsors.zero? && past_sponsors.zero?
      sponsor_summary = doc.at_css('p.f3-light.color-fg-muted.mb-3')&.text&.strip
      total_sponsors_match = sponsor_summary&.match(/(\d+)\s+sponsors/)
      current_sponsors = total_sponsors_match[1].to_i if total_sponsors_match
    end

    update sponsor_profile: {
      bio: bio,
      featured_works: featured_works,
      current_sponsors: current_sponsors,
      past_sponsors: past_sponsors
    }, last_synced_at: Time.now
  rescue => e
    puts "Error scraping sponsored page for #{login}"
    puts e
  end

  def kind
    data['kind']
  end

  def repositories_count
    data['repositories_count']
  end

  def description
    data['description']
  end

  def funding_links
    data['funding_links']
  end

  def current_sponsors
    sponsor_profile['current_sponsors'].to_i || 0
  end

  def past_sponsors
    sponsor_profile['past_sponsors'].to_i || 0
  end

  def total_sponsors
    current_sponsors + past_sponsors
  end

  def fetch_all_sponsors(filter: nil)
    page = 1
    sponsors = []
    while true
      url = "https://github.com/sponsors/#{login}/sponsors_partial?page=#{page}" + (filter ? "&filter=#{filter}" : "")
      resp = Faraday.get(url)
      break unless resp.status == 200
        
      doc = Nokogiri::HTML(resp.body)
      break if doc.at_css('.blankslate')

      logins = doc.css('.avatar').map { |avatar| avatar['alt'].gsub('@', '').downcase }
      break if logins.empty?
      sponsors += logins

      page += 1
      sleep 1
    end

    return sponsors
  rescue => e
    puts "Error fetching sponsors for #{login}"
    puts e
    return []
  end

  def sync_sponsorships
    return unless has_sponsors_listing?
    sponsors = fetch_all_sponsors(filter: 'active')
    sponsors.each do |login|
      funder = Account.find_or_create_by(login: login)
      # TODO sync funder
      s = Sponsorship.find_or_create_by(funder: funder, maintainer: self)
      s.update(status: 'active')
      funder.save
    end

    past_sponsors = fetch_all_sponsors(filter: 'inactive')
    past_sponsors.each do |login|
      funder = Account.find_or_create_by(login: login)
      # TODO sync funder
      s = Sponsorship.find_or_create_by(funder: funder, maintainer: self)
      s.update(status: 'inactive')
      funder.save
    end
  end

  def sync_funder
    data = fetch_sponsorships_github_graphql
    return unless data.present?

    data.each do |sponsor|
      maintainer = Account.find_or_create_by(login: sponsor['maintainer']['login'].downcase)
      s = Sponsorship.find_or_create_by(funder: self, maintainer: maintainer)
      s.update(status: 'active')
      maintainer.save
    end
  end

  def sync_funder_html
    data = fetch_sponsorships_github_html
    return unless data.present?

    data.each do |sponsor|
      maintainer = Account.find_or_create_by(login: sponsor['sponsorableLogin'].downcase)
      s = Sponsorship.find_or_create_by(funder: self, maintainer: maintainer)
      s.update(status: sponsor['active'] ? 'active' : 'inactive')
      maintainer.save
    end
  end

  def fetch_sponsorships_github_html
    kind = data['kind']
    if kind == 'user'
      url = "https://github.com/#{login}?tab=sponsoring"
      # requires pagination 

    else
      url = "https://github.com/orgs/#{login}/sponsoring"

      resp = Faraday.get(url)
      return unless resp.status == 200
          
      doc = Nokogiri::HTML(resp.body)
      target_partial = doc.at('react-partial[partial-name="your-sponsorships"]')
      if target_partial
        script_tag = target_partial.at('script[type="application/json"][data-target="react-partial.embeddedData"]')
      
        if script_tag
          json_data = script_tag.text.strip
          data = JSON.parse(json_data)
      
          pp data


          # Extract sponsorships
          sponsorships = data.dig('props', 'sponsorships') || []

          return sponsorships
        else
          puts "No embedded JSON found in the target react-partial."
        end
      else
        puts "No matching react-partial found."
      end
    end

    


    return sponsors
  end

  def fetch_sponsorships_github_graphql
    sponsors = []
    after_cursor = nil
  
    loop do
      query = <<~GRAPHQL
        query($after: String) {
          #{kind}(login: "#{login}") {
            sponsorshipsAsSponsor(first: 100, after: $after) {
              totalCount
              nodes {
                maintainer {
                  login
                  avatarUrl
                  bio
                }
              }
              pageInfo {
                endCursor
                hasNextPage
              }
            }
          }
        }
      GRAPHQL
  
      response = Faraday.post(
        "https://api.github.com/graphql",
        { query: query, variables: { after: after_cursor } }.to_json,
        {
          "Authorization" => "Bearer #{Account.fetch_random_token}",
          "Content-Type" => "application/json"
        }
      )
  
      break unless response.status == 200
  
      data = JSON.parse(response.body)

      user_data = data.dig('data', kind)
      break unless user_data
  
      sponsorships = user_data.dig('sponsorshipsAsSponsor')
      break unless sponsorships
  
      sponsors.concat(sponsorships['nodes'])
  
      page_info = sponsorships['pageInfo']
      break unless page_info['hasNextPage']
  
      after_cursor = page_info['endCursor']
    end
  
    return sponsors
  rescue => e
    puts "Error fetching sponsorships via GraphQL for #{login}"
    puts e
    return []
  end

  def self.token_set_key
    "github_tokens"
  end

  def self.list_tokens
    REDIS.smembers(token_set_key)
  end

  def self.fetch_random_token
    REDIS.srandmember(token_set_key)
  end

  def self.add_tokens(tokens)
    REDIS.sadd(token_set_key, tokens)
  end

  def self.remove_token(token)
    REDIS.srem(token_set_key, token)
  end

  def self.check_tokens
    list_tokens.each do |token|
      begin
        api_client(token).rate_limit!
      rescue Octokit::Unauthorized, Octokit::AccountSuspended
        puts "Removing token #{token}"
        remove_token(token)
      end
    end
  end

  def self.api_client(token = nil, options = {})
    token = fetch_random_token if token.nil?
    Octokit::Client.new({access_token: token}.merge(options))
  end
end
