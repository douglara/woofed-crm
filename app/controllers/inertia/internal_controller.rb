class Inertia::InternalController < InternalController
  inertia_share do
    {
      current_user: {
        id: current_user.id,
        email: current_user.email,
        full_name: current_user.full_name,
        language: current_user.language,
        avatar_url: current_user.avatar_url
      },
      current_account: {
        id: @account.id,
        name: @account.name
      }
    }
  end
end
