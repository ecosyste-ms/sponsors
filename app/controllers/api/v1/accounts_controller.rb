class Api::V1::AccountsController < Api::V1::ApplicationController
  before_action :ensure_lowercase_id, only: [:show]

  def index
    scope = Account.all.has_sponsors_listing.order('sponsors_count desc, updated_at DESC')
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
    scope = Account.all.where('sponsorships_count > 0').order('active_sponsorships_count desc, sponsorships_count desc, updated_at DESC')
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