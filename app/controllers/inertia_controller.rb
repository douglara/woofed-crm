# frozen_string_literal: true

class InertiaController < ApplicationController
  layout 'inertia'

  # Share data with all Inertia responses
  # see https://inertia-rails.dev/guide/shared-data
  inertia_share do
    {
      current_user: current_user&.as_json(only: %i[id full_name email]),
      current_account: Current.account&.as_json(only: %i[id name])
    }
  end
end
