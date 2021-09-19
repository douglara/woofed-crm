require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
 
  resources :contacts do
    get 'search', to: 'contacts#search', on: :collection
  end
  resources :deals do
    resources :notes, module: :deals
    resources :activities, module: :deals
    resources :flow_items, only: [:destroy], module: :deals
  end

  namespace :settings do
    get 'index'
    resources :activity_kinds
    namespace :whatsapp do
      get 'edit'
      post 'new_connection'
      get 'new_connection_status'
      post 'deactivate'
    end
  end

  resources :pipelines
  devise_for :users
  root to: "pipelines#index"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
