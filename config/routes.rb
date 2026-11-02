Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "paginas#inicio"

  resource :perfil, only: [ :edit, :update ], controller: "perfis"

  namespace :admin do
    resources :users, only: [ :index, :edit, :update ]
    resources :equipamentos, only: [ :index, :new, :create, :edit, :update ], param: :slug
  end

  resources :equipamentos, only: [ :index, :show ], param: :slug

  resources :academias, only: [ :index, :show, :new, :create, :edit, :update ]

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
