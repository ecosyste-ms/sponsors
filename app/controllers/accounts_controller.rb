class AccountsController < ApplicationController
  def index
    scope = Account.all.has_sponsors_profile.order('sponsors_count desc, updated_at DESC')
    @pagy, @accounts = pagy(scope)
  end

  def show
    @account = Account.find_by_login(params[:id])
  end
end