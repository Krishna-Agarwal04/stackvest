Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  scope :api do
    resource :wallet, only: [:show] do
      post :deposit, on: :collection
    end
    
    resources :transactions, only: [:index]
    get :dashboard, to: "dashboard#index"

    resources :stacks, only: [:index, :show] do
      post :payout_yields, on: :collection
      member do
        post :bid, to: "stacks#place_bid"
        post :buy, to: "stacks#buy_outright"
        post :sell, to: "stacks#sell"
      end
    end
  end
end

