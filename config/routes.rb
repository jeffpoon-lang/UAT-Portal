Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  namespace :admin do
    root "dashboard#show"
    resources :clients, except: :destroy
    resources :projects, except: :destroy do
      resources :test_cases, except: [ :index, :show ]
      resources :uat_rounds, only: [ :create, :show ] do
        post :summarise, on: :member
      end
      resources :change_requests, only: [ :new, :create ] do
        member do
          post :approve
          post :reject
        end
      end
    end
    resources :sign_offs, only: [ :index, :show ] do
      post :verify, on: :collection
    end
    resources :tickets, only: [ :index, :show, :update ] do
      resources :logs, only: :create, controller: "ticket_logs"
    end
    get "reports/maintenance", to: "reports#maintenance", as: :maintenance_report
  end

  namespace :portal do
    resources :projects, only: [ :index, :show ] do
      resources :uat_rounds, only: :show do
        member do
          post :request_changes
          post :sign_off
        end
        resources :test_results, only: :update
      end
      resources :tickets, only: [ :new, :create, :show ]
    end
    resources :sign_offs, only: :show
  end

  # 截圖由 Postgres 讀出嚟（active_storage_db）
  mount ActiveStorageDB::Engine => "/active_storage_db"

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#show"
end
