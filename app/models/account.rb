class Account < ApplicationRecord
  validates :login, presence: true

  scope :has_sponsors_listing, -> { where(has_sponsors_listing: true) }

  def self.import_from_repos
    url = 'https://repos.ecosyste.ms/api/v1/hosts/GitHub/owners/sponsors_logins'

    resp = Faraday.get(url)

    return unless resp.status == 200

    logins = JSON.parse(resp.body)

    logins.map(&:downcase).each do |login|
      account = Account.find_or_create_by(login: login)
      account.update(has_sponsors_listing: true)
    end
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

  def sync
    resp = Faraday.get(repos_api_url)

    return unless resp.status == 200

    data = JSON.parse(resp.body)

    update(
      last_synced_at: Time.now,
      data: data
    )
  end

  def sync_async
    # TODO
  end

  def scrape_sponsored_page
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

    sponsors = doc.at_css('#sponsors')&.css('.avatar')&.map { |avatar| avatar['alt'] } || []

    c4 = doc.at('h4:contains("Current sponsors")')
    current_sponsors = c4&.at('span.Counter')&.text&.delete(',') || 0
    
    p4 = doc.at('h4:contains("Past sponsors")')
    past_sponsors = p4&.at('span.Counter')&.text&.delete(',') || 0

    update sponsor_profile: {
      bio: bio,
      featured_works: featured_works,
      sponsors: sponsors,
      current_sponsors: current_sponsors,
      past_sponsors: past_sponsors
    }
  end
end
