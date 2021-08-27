Rails.application.routes.draw do
  resources :contacts
  resources :deals do
    resources :notes, module: :deals
  end

  resources :pipelines
  devise_for :users
  root to: "pipelines#index"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
