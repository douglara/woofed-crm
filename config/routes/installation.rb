# frozen_string_literal: true

if Installation.installation_flow?
  namespace :installation do
    get :new
    get :create
    get :step_1
    get :step_2
    get :step_3
    patch :update_step_1
    patch :update_step_2
    patch :update_step_3
    get :loading
  end
end
