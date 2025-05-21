require 'sidekiq/web'

Rails.application.routes.draw do
  mount Motor::Admin => '/motor_admin'
  mount Sidekiq::Web => '/sidekiq'
  mount GoodJob::Engine => 'good_job'

  draw(:installation)

  resources :accounts, module: :accounts do
    resources :webpush_subscriptions, only: [:create]
    resources :settings, only: [:index]
    resources :welcome, only: [:index]
    resources :custom_attributes_definitions, module: :settings do
    end

    resources :webhooks, module: :settings do
    end

    resources :users do
      get 'select_user_search', on: :collection
    end
    resources :products do
      get 'edit_custom_attributes', on: :member
      patch 'update_custom_attributes', on: :member
      get 'select_product_search', on: :collection
    end
    resources :contacts do
      get 'search', to: 'contacts#search', on: :collection
      get 'edit_custom_attributes'
      get 'chatwoot_conversation_link', on: :member
      patch 'update_custom_attributes'
      get 'select_contact_search', on: :collection
      resources :events, module: :contacts do
      end
      namespace :events, module: :contacts do
        namespace :apps, module: :events do
        end
      end

      collection do
        resources :chatwoot_embed, only: %i[show new create], controller: 'contacts/chatwoot_embed' do
          post 'search', on: :collection
        end
      end
      get 'hovercard_preview', on: :member
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
      patch 'update_deal_product', on: :member
      get 'edit_deal_product', on: :member
      get 'deal_products', on: :member
      get 'deal_assignees', on: :member
      get 'events_to_do', on: :member
      get 'events_done', on: :member
      get 'add_contact'
      post 'commit_add_contact'
      delete 'remove_contact'
      get 'new_select_contact', on: :collection
      get 'edit_custom_attributes'
      patch 'update_custom_attributes'
    end
    resources :deal_products, only: %i[destroy new create]
    resources :deal_assignees, only: %i[destroy new create]

    namespace :apps do
      resources :evolution_apis do
        member do
          get 'pair_qr_code'
          post 'refresh_qr_code'
        end
      end
      resources :chatwoots
      # resources :events, module: :contacts
      resource :ai_assistent, only: %i[edit update]
    end
    resources :attachments, only: [:destroy]
    resources :stages, only: [:show]
  end
  if ENV.fetch('ENABLE_USER_SIGNUP', 'false') == 'true'
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
          # resources :events, module: :contacts
        end
        resources :deal_products, only: %i[create show]
        resources :products, only: %i[create show] do
          match 'search', on: :collection, via: %i[get post]
        end
      end

      resources :contacts, only: [:create] do
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
  get 'service-worker' => 'pwa#service_worker'
  get 'webmanifest' => 'pwa#manifest'
end
