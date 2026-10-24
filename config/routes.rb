Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  namespace :admin do
    root "dashboard#show"
    resources :clients, except: :destroy
    resources :projects, except: :destroy do
      resources :test_cases, except: [ :index, :show ]
    end
  end

  namespace :portal do
    resources :projects, only: [ :index, :show ]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#show"
end
