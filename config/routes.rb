require 'sidekiq/web'

Rails.application.routes.draw do
  mount Motor::Admin => '/motor_admin'
  mount Sidekiq::Web => '/sidekiq'
  mount GoodJob::Engine => 'good_job'

  resources :accounts, module: :accounts do
    resources :settings, only: [:index]
    resources :welcome, only: [:index]
    resources :custom_attributes_definitions, module: :settings do
    end

    resources :webhooks, module: :settings do
    end
    resources :ai, module: :settings, only: %i[edit update]

    # namespace :settings do
    #   get 'index' #, controller: "accounts/settings"
    #   resources :activity_kinds
    #   resources :whatsapp do
    #     post 'pair_qr_code', on: :collection
    #     post 'new_connection_status', on: :collection
    #     post 'disable'
    #   end
    # end
    resources :users
    resources :products do
      get 'edit_custom_attributes', on: :member
      patch 'update_custom_attributes', on: :member
    end
    resources :contacts do
      get 'search', to: 'contacts#search', on: :collection
      get 'edit_custom_attributes'
      patch 'update_custom_attributes'
      get 'select_contact_search', on: :collection
      resources :notes, module: :contacts
      resources :events, module: :contacts do
      end
      namespace :events, module: :contacts do
        namespace :apps, module: :events do
          namespace :wpp_connects, module: :apps do
            resources :messages, module: :wpp_connects
          end
        end
      end

      collection do
        resources :chatwoot_embed, only: %i[show new create], controller: 'contacts/chatwoot_embed' do
          post 'search', on: :collection
        end
      end
    end
    resources :pipelines do
      get 'import'
      post 'import_file'
      get 'export'
      member do
        get 'new_bulk_action'
        get 'bulk_action'
        post 'create_bulk_action'
      end
    end

    resources :deals do
      patch 'update_product', on: :member
      get 'edit_product', on: :member
      get 'deal_products', on: :member
      get 'events_to_do', on: :member
      get 'events_done', on: :member
      post 'create_whatsapp'
      get 'add_contact'
      post 'commit_add_contact'
      delete 'remove_contact'
      get 'new_select_contact', on: :collection
      get 'edit_custom_attributes'
      patch 'update_custom_attributes'
      resources :activities, module: :deals
      resources :flow_items, only: [:destroy], module: :deals
    end
    resources :deal_products, only: %i[destroy new create] do
      get 'select_product_search', on: :collection
    end

    namespace :apps do
      resources :wpp_connects do
        get 'pair_qr_code'
        post 'new_connection_status'
        post 'disable'
      end
      resources :evolution_apis, except: [:destroy] do
        member do
          get 'pair_qr_code'
          post 'refresh_qr_code'
        end
      end
      resources :chatwoots
      # resources :events, module: :contacts
    end
  end
  if ENV.fetch('ENABLE_USER_SIGNUP', 'true') == 'true'
    devise_for :users, controllers: {
      registrations: 'users/registrations'
    }
  else
    devise_for :users, skip: [:registrations]
  end

  root to: 'accounts/pipelines#index'

  namespace :api do
    namespace :v1 do
      resources :accounts, module: :accounts do
        resources :deals, only: %i[show create update] do
          post 'upsert', on: :collection
          resources :events, only: [:create], module: :deals do
          end
        end
        resources :contacts, only: %i[show create] do
          post 'upsert', on: :collection
          match 'search', on: :collection, via: %i[get post]
        end
        namespace :apps do
          resources :wpp_connects, only: [] do
            post 'webhook'
          end
          # resources :events, module: :contacts
        end
      end

      namespace :flow_items do
        resources :wp_connects do
          post 'webhook'
        end
      end
      resources :contacts, only: [:create] do
        resources :wp_connects, only: [] do
          resources :messages, only: [:create], controller: 'contacts/wp_connects/messages'
        end
      end
    end
  end

  namespace :embedded do
    resources :accounts, module: :accounts do
      namespace :apps do
        resources :chatwoots, only: [:index] do
        end
      end
    end
  end

  namespace :apps do
    resources :chatwoots do
      collection do
        post 'webhooks'
        get 'embedding'
        get 'embedding_init_authenticate'
        post 'embedding_authenticate'
      end
    end
    resources :evolution_apis do
      collection do
        post 'webhooks'
      end
    end
  end
end
