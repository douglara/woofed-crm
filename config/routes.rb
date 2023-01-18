require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  resources :accounts, module: :accounts do
    resources :settings, only: [:index]
        resources :custom_attributes_definitions, module: :settings do

        end
      # namespace :settings do
      #   get 'index' #, controller: "accounts/settings"
      #   resources :activity_kinds
      #   resources :whatsapp do
      #     post 'pair_qr_code', on: :collection
      #     post 'new_connection_status', on: :collection
      #     post 'disable'
      #   end
      # end
      resources :contacts do
        get 'search', to: 'contacts#search', on: :collection
        resources :notes, module: :contacts
        resources :events, module: :contacts
      end
      resources :pipelines do
        get 'import'
        get 'bulk_action'
        get 'bulk_action_2'
      end
      
      resources :deals do
        post 'create_whatsapp'
        get 'add_contact'
        post 'commit_add_contact'
        delete 'remove_contact'
        get 'new_select_contact', on: :collection
        resources :activities, module: :deals
        resources :flow_items, only: [:destroy], module: :deals
      end
  end
 
  devise_for :users
  root to: "accounts/pipelines#index"

  namespace :api do
    namespace :v1 do
      namespace :flow_items do
        resources :wp_connects do
          post 'webhook'
        end  
      end
      resources :contacts, only: [:create] do
        resources :wp_connects, only: [] do
          resources :messages, only: [:create], controller: "contacts/wp_connects/messages"
        end
      end
    end
  end
end
