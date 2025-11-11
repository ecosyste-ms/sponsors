class AccountsController < ApplicationController
  before_action :ensure_lowercase_id, only: [:show]

  def index
    if params[:active] == 'true'
      scope = Account.all.has_sponsors_listing.where('active_sponsors_count > 0')
    else
      scope = Account.all.has_sponsors_listing
    end
    scope = scope.kind(params[:kind]) if params[:kind].present?

    if params[:sort].present? || params[:order].present?
      sort = params[:sort].presence || 'active_sponsorships_count'
      if params[:order] == 'asc'
        scope = scope.order(Arel.sql(sort).asc.nulls_last)
      else
        scope = scope.order(Arel.sql(sort).desc.nulls_last)
      end
    else
      scope = scope.order('sponsors_count desc, updated_at DESC')
    end

    @pagy, @accounts = pagy(scope)
  end

  def show

    @account = Account.find_by_login(params[:id].downcase)
    raise ActiveRecord::RecordNotFound if @account.nil?
  end

  def sponsors
    if params[:active] == 'true'
      scope = Account.all.where('active_sponsorships_count > 0')
    else
      scope = Account.all.where('sponsorships_count > 0')
    end
    scope = scope.kind(params[:kind]) if params[:kind].present?

    if params[:sort].present? || params[:order].present?
      sort = params[:sort].presence || 'active_sponsorships_count'
      if params[:order] == 'asc'
        scope = scope.order(Arel.sql(sort).asc.nulls_last)
      else
        scope = scope.order(Arel.sql(sort).desc.nulls_last)
      end
    else
      scope = scope.order('active_sponsorships_count desc, sponsorships_count desc, updated_at DESC')
    end

    @pagy, @accounts = pagy(scope)
  end

  def charts
    @accounts_by_total_sponsorships = Account.all
      .has_sponsors_listing
      .order(sponsors_count: :desc)
      .limit(1000)
      .pluck(:login, :sponsors_count)
    
    @top_50_accounts_by_total_sponsorships = @accounts_by_total_sponsorships.first(50)

    @top_1000_users_by_total_sponsorships = Account.users
      .has_sponsors_listing
      .order(sponsors_count: :desc)
      .limit(1000)
      .pluck(:login, :sponsors_count)
    
    @top_50_users_by_total_sponsorships = @top_1000_users_by_total_sponsorships.first(50)

    @top_1000_organizations_by_total_sponsorships = Account.organizations
      .has_sponsors_listing
      .order(sponsors_count: :desc)
      .limit(1000)
      .pluck(:login, :sponsors_count)

    @top_50_organizations_by_total_sponsorships = @top_1000_organizations_by_total_sponsorships.first(50)

    @critical_packages = load_critical_packages
  
    ecosystem_counts = @critical_packages.each_with_object(Hash.new(0)) { |pkg, counts| counts[pkg['ecosystem']] += 1 }

    # Sort ecosystems by frequency (most frequent first)
    @ecosystems = ecosystem_counts.sort_by { |_, count| -count }.map(&:first)
  end

  def sponsor_charts
    @accounts_by_total_sponsors = Account.all
      .where('sponsorships_count > 0').order('sponsorships_count desc')
      .limit(1000)
      .pluck(:login, :sponsorships_count)

    @top_50_accounts_by_total_sponsors = @accounts_by_total_sponsors.first(50)
    
    @top_1000_users_by_total_sponsors = Account.users
      .where('sponsorships_count > 0').order('sponsorships_count desc')
      .limit(1000)
      .pluck(:login, :sponsorships_count)
    
    @top_50_users_by_total_sponsors = @top_1000_users_by_total_sponsors.first(50)

    @top_1000_organizations_by_total_sponsors = Account.organizations
      .where('sponsorships_count > 0').order('sponsorships_count desc')
      .limit(1000)
      .pluck(:login, :sponsorships_count)

    @top_50_organizations_by_total_sponsors = @top_1000_organizations_by_total_sponsors.first(50)
  end

  private 

  def load_critical_packages
    Rails.cache.fetch('critical_packages', expires_in: 1.week) do
      critical_packages = []
      page = 1

      loop do
        url = "https://packages.ecosyste.ms/api/v1/packages/critical?funding=true&per_page=1000&page=#{page}"
        response = Faraday.get(url) do |req|
          req.headers['User-Agent'] = 'sponsors.ecosyste.ms'
        end
        data = JSON.parse(response.body)
        break if data.empty?
        data.each do |package|
          critical_packages << package if package['funding_links'].any?{|link| link.include?('github.com/sponsors') } && !%w[docker puppet].include?(package['ecosystem'])
        end
        page += 1
      end

      critical_packages
    end
  end
end