# frozen_string_literal: true

class UsersResource < ApplicationResource
  uri_template 'woofed:///users/{id}'
  resource_name 'user'
  description 'A user record, including the deals the user is assigned to.'
  mime_type 'application/json'

  def content
    user = User.find(params[:id])
    JSON.generate(
      user.as_json(
        only: %i[id full_name email phone job_description language avatar_url created_at updated_at],
        include: :deals
      )
    )
  end
end
