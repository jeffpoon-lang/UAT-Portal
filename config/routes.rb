Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :password_change, only: [ :edit, :update ]

  namespace :admin do
    root "dashboard#show"
    resources :clients, except: :destroy do
      resource :retainer_plan, only: [ :new, :create, :edit, :update ] do
        post :give_notice
        post :withdraw_notice
      end
      resources :users, only: [ :new, :create ]
    end
    resources :users, only: :destroy do
      post :reset_password, on: :member
    end
    resources :handover_items, only: :update
    resources :monthly_updates, only: :create
    get "retention", to: "retention#show", as: :retention
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
    resource :retainer, only: :show
    resources :handover_items, only: :update
  end

  # 截圖由 Postgres 讀出嚟（active_storage_db）
  mount ActiveStorageDB::Engine => "/active_storage_db"

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#show"
end
