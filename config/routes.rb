Rails.application.routes.draw do
  resources :deals
  resources :pipelines
  devise_for :users
  root to: "pipelines#index"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
