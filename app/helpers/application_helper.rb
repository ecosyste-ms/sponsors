module ApplicationHelper
  include Pagy::Frontend
  include SanitizeUrl
  
  def meta_title
    [@meta_title, 'Ecosyste.ms: Sponsors'].compact.join(' | ')
  end

  def meta_description
    @meta_description || app_description
  end

  def app_name
    "Sponsors"
  end

  def app_description
    'An open API service aggregating public data about GitHub Sponsors.'
  end

  def sanitize_user_url(url)
    return unless url && url.is_a?(String)
    return unless url =~ /\A#{URI::regexp}\z/
    sanitize_url(url, :schemes => ['http', 'https'])
  end

  def bootstrap_icon(symbol, options = {})
    return "" if symbol.nil?
    icon = BootstrapIcons::BootstrapIcon.new(symbol, options)
    content_tag(:svg, icon.path.html_safe, icon.options)
  end
end
