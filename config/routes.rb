Rails.application.routes.draw do
  get "order_items/index"
  get "order_items/show"
  get "order_items/create"
  get "order_items/update"
  get "order_items/destroy"
  get "orders/index"
  get "orders/show"
  get "orders/create"
  get "orders/update"
  get "orders/destroy"
  get "products/index"
  get "products/show"
  get "products/create"
  get "products/update"
  get "products/destroy"
  resources :sellers do
    member do
      patch :activate
      patch :deactivate
      put :busy_status
    end
    collection do
      get 'by_external_id/:external_id', to: 'sellers#by_external_id'
    end
  end
        get '/stores/:slug/sellers', to: 'sellers#by_store_slug'
      get '/stores/:slug/sellers/ranking', to: 'sellers#ranking'
  
  # Rotas de autenticação
  post '/auth/login', to: 'auth#login'
  post '/auth/register', to: 'auth#register'
  post '/auth/logout', to: 'auth#logout'
  get '/auth/me', to: 'auth#me'
  post '/auth/generate_api_token', to: 'auth#generate_api_token'
  
  # Rotas de companies (protegidas por autenticação)
  resources :companies, except: [:new, :edit] do
    resources :stores, only: [:index]
  end
  
  # Rotas de stores (protegidas por autenticação)
  resources :stores
  get '/stores/by-slug/:slug', to: 'stores#show_by_slug'
  get '/stores/by-external-id/:external_id', to: 'stores#show_by_external_id'
  
  # Rotas de turnos, escalas, ausências, metas e comissionamento (protegidas por autenticação)
  resources :shifts, except: [:new, :edit]
  
  # Rotas específicas para turnos de loja
  get '/stores/:store_slug/shifts', to: 'shifts#index'
  post '/stores/:store_slug/shifts', to: 'shifts#create'
  get '/stores/:store_slug/shifts/:id', to: 'shifts#show'
  put '/stores/:store_slug/shifts/:id', to: 'shifts#update'
  delete '/stores/:store_slug/shifts/:id', to: 'shifts#destroy'
  resources :schedules, except: [:new, :edit]
  resources :absences, except: [:new, :edit]
  get 'absences/current', to: 'absences#current'
  resources :vacations, except: [:new, :edit] # Manter por compatibilidade
  resources :goals, except: [:new, :edit] do
    member do
      post :recalculate_progress
    end
  end
  resources :categories, except: [:new, :edit]
  resources :products, except: [:new, :edit]
  resources :orders, except: [:new, :edit] do
    collection do
      post :load_orders
      post :bulk_load_orders
      post :bulk_load_orders_with_items
    end
  end
  resources :order_items, except: [:new, :edit] do
    collection do
      post :load_order_items
      post :bulk_load_order_items
    end
  end
  
  # Rotas de comissionamento por loja
  get '/stores/:store_slug/commission_levels', to: 'commission_levels#index'
  post '/stores/:store_slug/commission_levels', to: 'commission_levels#create'
  get '/stores/:store_slug/commission_levels/:id', to: 'commission_levels#show'
  put '/stores/:store_slug/commission_levels/:id', to: 'commission_levels#update'
  delete '/stores/:store_slug/commission_levels/:id', to: 'commission_levels#destroy'
  
  # Rotas de usuários (apenas para admins)
  resources :users do
    collection do
      get :available
    end
  end
  
  # Rotas de métricas (apenas para admins)
  get '/metrics', to: 'metrics#index'
  
  # Rota de documentação da API
  get '/api/docs', to: 'api_docs#index'
  get '/api/docs/html', to: 'api_docs#html'
  
  # Rotas de dashboard
  get '/dashboard', to: 'dashboard#admin_dashboard'
  get '/stores/:slug/dashboard', to: 'dashboard#store_dashboard'
  
  # Rotas de fila de atendimento
  get '/stores/:slug/queue', to: 'queue#index'
  post '/stores/:slug/queue', to: 'queue#create'
  get '/stores/:slug/queue/stats', to: 'queue#stats'
  get '/stores/:slug/queue/next', to: 'queue#next_customer'
  post '/stores/:slug/queue/auto_assign', to: 'queue#auto_assign'
  
  resources :queue, only: [:show, :update, :destroy], controller: 'queue' do
    member do
      put :assign
      put :complete
      put :cancel
    end
  end
  
  # Rotas de ajustes financeiros
  get '/stores/:slug/adjustments', to: 'adjustments#index'
  post '/stores/:slug/adjustments', to: 'adjustments#create'
  get '/stores/:slug/adjustments/stats', to: 'adjustments#stats'
  
  resources :adjustments, only: [:show, :update, :destroy]
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  match '*path', to: proc { [204, {}, ['']] }, via: [:options]

  # Test route
  get '/test', to: 'test#index'
  
  # Defines the root path route ("/")
  # root "posts#index"
end
