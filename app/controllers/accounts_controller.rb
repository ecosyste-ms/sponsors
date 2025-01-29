class AccountsController < ApplicationController
  def index
    scope = Account.all.has_sponsors_listing.order('sponsors_count desc, updated_at DESC')
    scope = scope.kind(params[:kind]) if params[:kind].present?
    @pagy, @accounts = pagy(scope)
  end

  def show
    @account = Account.find_by_login(params[:id].downcase)
    raise ActiveRecord::RecordNotFound if @account.nil?
  end

  def sponsors
    scope = Account.all.where('sponsorships_count > 0').order('active_sponsorships_count desc, sponsorships_count desc, updated_at DESC')
    scope = scope.kind(params[:kind]) if params[:kind].present?
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
end