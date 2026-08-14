resources :accounts, module: :accounts, only: [] do
  resources :world_clocks, only: [:index]
end
