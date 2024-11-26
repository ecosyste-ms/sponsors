class AccountsController < ApplicationController
  def index
    scope = Account.all.has_sponsors_profile.where('sponsors_count > 0').order('sponsors_count desc, updated_at DESC')
    @pagy, @accounts = pagy(scope)
  end

  def show
    @account = Account.find_by_login(params[:id])
  end

  def sponsors
    scope = Account.all.where('sponsorships_count > 0').order('active_sponsorships_count desc, sponsorships_count desc, updated_at DESC')
    @pagy, @accounts = pagy(scope)
  end
end