require 'sidekiq_unique_jobs/web'
require 'sidekiq/web'

Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
end if Rails.env.production?

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  mount PgHero::Engine, at: "pghero"

  mount Rswag::Ui::Engine => '/docs'
  mount Rswag::Api::Engine => '/docs'

  namespace :api, :defaults => {:format => :json} do
    namespace :v1 do
      resources :accounts, only: [:index, :show] do
        get 'sponsors', to: 'accounts#account_sponsors'
        get 'sponsorships', to: 'accounts#sponsorships'
      end
      get 'sponsors', to: 'accounts#sponsors'
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  resources :accounts, only: [:index, :show]

  get 'sponsors', to: 'accounts#sponsors', as: :sponsors
  get 'charts', to: 'accounts#charts', as: :charts

  root to: "accounts#index"
end
