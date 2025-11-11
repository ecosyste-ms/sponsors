class Api::V1::AccountsController < Api::V1::ApplicationController
  before_action :ensure_lowercase_id, only: [:show]

  def index
    if params[:active] == 'true'
      scope = Account.all.has_sponsors_listing.where('active_sponsors_count > 0')
    else
      scope = Account.all.has_sponsors_listing
    end
    scope = scope.order('sponsors_count desc, updated_at DESC')
    @pagy, @accounts = pagy(scope)
  end

  def show
    @account = Account.find_by_login(params[:id].downcase)
    if @account.nil?
      @account = Account.attempt_import_from_repos(params[:id].downcase)
      raise ActiveRecord::RecordNotFound if @account.nil?
    end
  end

  def sponsors
    if params[:active] == 'true'
      scope = Account.all.where('active_sponsorships_count > 0')
    else
      scope = Account.all.where('sponsorships_count > 0')
    end
    scope = scope.order('active_sponsorships_count desc, sponsorships_count desc, updated_at DESC')
    @pagy, @accounts = pagy(scope)
    render :index
  end

  def sponsorships
    @account = Account.find_by_login(params[:account_id].downcase)
    raise ActiveRecord::RecordNotFound unless @account
    scope = @account.sponsorships_as_maintainer.order('created_at DESC').includes(:maintainer, :funder)
    @pagy, @sponsorships = pagy(scope)
    render 'api/v1/sponsorships/index'
  end

  def account_sponsors
    @account = Account.find_by_login(params[:account_id].downcase)
    raise ActiveRecord::RecordNotFound unless @account
    scope = @account.sponsorships_as_funder.order('created_at DESC').includes(:maintainer, :funder)
    @pagy, @sponsorships = pagy(scope)
    render 'api/v1/sponsorships/index'
  end

  def sponsor_logins
    logins = Account.has_sponsors_listing.order('login').pluck(:login)
    render json: logins
  end
end