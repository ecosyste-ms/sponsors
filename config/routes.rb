Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :accounts, only: [:index, :show]

  root to: "accounts#index"
end
