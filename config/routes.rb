Rails.application.routes.draw do
  devise_for :users, controllers: {omniauth_callbacks: "omniauth_callbacks"}

  root to: 'welcome#index'

  get '/register' => 'welcome#register'
  get '/logout' => 'welcome#logout'
  get '/evaluate' => 'vessels#evaluate'
  post '/detail' => 'vessels#detail'

  # competitions are top level objects
  resources :competitions, only: [:new, :create, :index, :show, :update] do
    member do
      get :generate
      get :start
      get :extend
      get :stop
      get :results
    end
    resources :players, only: :index, controller: 'competitions/players'
    resources :vessels, only: [:index, :new, :create] do
      collection do
        get :upload
        post :batch
      end
    end
    resources :heats, only: [:index, :show] do
      member do 
        get :start
        get :stop
        get :reset
      end
      resources :vessels, only: :index, controller: 'heats/vessels'
      resources :records, only: :index
      post 'records/batch'
    end
    resources :rules, only: [:index, :new, :create, :destroy]
  end

  # players are top level objects
  resources :players do
    member do
      get :chart
    end
    collection do
      get :register
    end
  end

  # rescue bad routes
  match '*unmatched', to: 'application#bad_request', via: :all
end
