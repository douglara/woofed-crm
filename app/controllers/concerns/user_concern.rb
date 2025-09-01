module UserConcern
  def permitted_user_params
    %i[email password password_confirmation full_name phone language avatar_url job_description
                                 webpush_notify_on_event_expired]
  end
end
