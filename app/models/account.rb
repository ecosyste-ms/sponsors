class Account < ApplicationRecord
  validates :login, presence: true

  has_many :sponsorships_as_funder, class_name: "Sponsorship", foreign_key: :funder_id
  has_many :sponsorships_as_maintainer, class_name: "Sponsorship", foreign_key: :maintainer_id

  has_many :maintained_accounts, through: :sponsorships_as_funder, source: :maintainer
  has_many :funder_accounts, through: :sponsorships_as_maintainer, source: :funder

  scope :has_sponsors_listing, -> { where(has_sponsors_listing: true) }
  scope :has_sponsors_profile, -> { where('length(sponsor_profile::text) > 2') }

  scope :with_sponsors, -> { where('sponsors_count > 0') }
  scope :with_sponsorships, -> { where('sponsorships_count > 0') }

  before_save :set_sponsors_count

  def to_s
    login
  end

  def to_param
    login
  end

  def set_sponsors_count
    self.sponsors_count = total_sponsors == 0 ? sponsorships_as_maintainer.count : total_sponsors
    self.sponsorships_count = sponsorships_as_funder.count
    self.active_sponsorships_count = sponsorships_as_funder.active.count
  end

  def self.import_from_repos
    url = 'https://repos.ecosyste.ms/api/v1/hosts/GitHub/owners/sponsors_logins'

    resp = Faraday.get(url)

    return unless resp.status == 200

    logins = JSON.parse(resp.body)

    logins.map(&:downcase).each do |login|
      account = Account.find_or_create_by(login: login)
      account.update(has_sponsors_listing: true) if account.changed?
    end
  end

  def ping_repos
    Faraday.get(repos_api_url + '/ping') 
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

    ping_repos

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
  end

  def sync_async
    # TODO
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
end
