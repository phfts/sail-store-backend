Rails.application.routes.draw do
  resources :sellers
  # Rotas de autenticação
  post '/auth/login', to: 'auth#login'
  post '/auth/register', to: 'auth#register'
  post '/auth/logout', to: 'auth#logout'
  get '/auth/me', to: 'auth#me'
  
  # Rotas de stores (protegidas por autenticação)
  resources :stores
  
  # Rotas de usuários (apenas para admins)
  resources :users
  
  # Rotas de métricas (apenas para admins)
  get '/metrics', to: 'metrics#index'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  match '*path', to: proc { [204, {}, ['']] }, via: [:options]

  # Defines the root path route ("/")
  # root "posts#index"
end
