class Api::V1::AccountsController < Api::V1::ApplicationController
  def index
    scope = Account.all.has_sponsors_profile.order('sponsors_count desc, updated_at DESC')
    @pagy, @accounts = pagy(scope)
  end

  def show
    @account = Account.find_by_login(params[:id])
  end

  def sponsors
    scope = Account.all.where('sponsorships_count > 0').order('active_sponsorships_count desc, sponsorships_count desc, updated_at DESC')
    @pagy, @accounts = pagy(scope)
    render :index
  end
end