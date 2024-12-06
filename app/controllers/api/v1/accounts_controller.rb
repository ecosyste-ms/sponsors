class Api::V1::AccountsController < Api::V1::ApplicationController
  def index
    scope = Account.all.has_sponsors_listing.order('sponsors_count desc, updated_at DESC')
    @pagy, @accounts = pagy(scope)
  end

  def show
    @account = Account.find_by_login(params[:id])
    raise ActiveRecord::RecordNotFound unless @account
  end

  def sponsors
    scope = Account.all.where('sponsorships_count > 0').order('active_sponsorships_count desc, sponsorships_count desc, updated_at DESC')
    @pagy, @accounts = pagy(scope)
    render :index
  end

  def sponsorships
    @account = Account.find_by_login(params[:account_id])
    raise ActiveRecord::RecordNotFound unless @account
    scope = @account.sponsorships_as_maintainer.order('created_at DESC').includes(:maintainer, :funder)
    @pagy, @sponsorships = pagy(scope)
    render 'api/v1/sponsorships/index'
  end

  def account_sponsors
    @account = Account.find_by_login(params[:account_id])
    raise ActiveRecord::RecordNotFound unless @account
    scope = @account.sponsorships_as_funder.order('created_at DESC').includes(:maintainer, :funder)
    @pagy, @sponsorships = pagy(scope)
    render 'api/v1/sponsorships/index'
  end
end