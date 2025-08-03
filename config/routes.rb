Rails.application.routes.draw do
  resources :sellers do
    member do
      patch :activate
      patch :deactivate
    end
  end
  get '/stores/:slug/sellers', to: 'sellers#by_store_slug'
  
  # Rotas de autenticação
  post '/auth/login', to: 'auth#login'
  post '/auth/register', to: 'auth#register'
  post '/auth/logout', to: 'auth#logout'
  get '/auth/me', to: 'auth#me'
  
  # Rotas de stores (protegidas por autenticação)
  resources :stores
  get '/stores/by-slug/:slug', to: 'stores#show_by_slug'
  
  # Rotas de turnos, escalas, férias, metas e vendas (protegidas por autenticação)
  resources :shifts, except: [:new, :edit]
  resources :schedules, except: [:new, :edit]
  resources :vacations, except: [:new, :edit]
  resources :goals, except: [:new, :edit]
  resources :sales, except: [:new, :edit]
  
  # Rotas de usuários (apenas para admins)
  resources :users do
    collection do
      get :available
    end
  end
  
  # Rotas de métricas (apenas para admins)
  get '/metrics', to: 'metrics#index'
  
  # Rotas de dashboard
  get '/dashboard', to: 'dashboard#admin_dashboard'
  get '/stores/:slug/dashboard', to: 'dashboard#store_dashboard'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  match '*path', to: proc { [204, {}, ['']] }, via: [:options]

  # Defines the root path route ("/")
  # root "posts#index"
end
