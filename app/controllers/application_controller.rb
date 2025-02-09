class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :set_custom_headers

  private

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
end
