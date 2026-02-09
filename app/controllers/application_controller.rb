class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :set_custom_headers
  before_action :set_cache_headers

  def set_cache_headers(browser_ttl: 5.minutes, cdn_ttl: 6.hours)
    return unless request.get?
    response.cache_control.merge!(
      public: true,
      max_age: browser_ttl.to_i,
      stale_while_revalidate: cdn_ttl.to_i,
      stale_if_error: 1.day.to_i
    )
    response.cache_control[:extras] = ["s-maxage=#{cdn_ttl.to_i}"]
  end

  def set_custom_headers
    response.set_header('Organization', 'Ecosyste.ms (contact@ecosyste.ms)')

    response.set_header('Link', [
      '<https://creativecommons.org/licenses/by-sa/4.0/>; rel="license"',
      '<https://github.com/ecosyste-ms>; rel="source"',
      '<https://opencollective.com/ecosystems>; rel="payment"',
      '<mailto:contact@ecosyste.ms>; rel="author"',
      '<https://ecosyste.ms/privacy>; rel="privacy-policy"',
      '<https://ecosyste.ms/terms>; rel="terms-of-service"',
      '<https://ecosyste.ms>; rel="self"',
      '<https://ecosyste.ms>; rel="home"',
      '<https://ecosyste.ms/about>; rel="about"',
      '<https://ecosyste.ms>; rel="cite-as"',
      '<https://mastodon.social/@ecosystems>; rel="me"',
    ].join(", "))
  end

  def ensure_lowercase_id
    if params[:id] != params[:id].downcase
      redirect_to action: action_name, id: params[:id].downcase, status: :moved_permanently
    end
  end
end
