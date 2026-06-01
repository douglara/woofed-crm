class BackfillWoofedAiTokensForUsers < ActiveRecord::Migration[7.1]
  # Mints a long-lived Doorkeeper access token (scope `mcp`) for every existing
  # user so the Python agent (ai-agent/) can call /mcp on the user's behalf.
  # Going forward, the same logic runs in an `after_create` on User. The token's
  # `resource` claim is bound to `<FRONTEND_URL>/mcp` per RFC 8707.
  WOOFED_AI_APP_NAME = 'Woofed AI'

  def up
    base_url = ENV['FRONTEND_URL']&.chomp('/')
    raise 'FRONTEND_URL is required to mint MCP tokens during migration' if base_url.blank?

    app = Doorkeeper::Application.find_or_create_by!(name: WOOFED_AI_APP_NAME) do |a|
      a.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
      a.scopes = 'mcp'
      a.confidential = true
    end

    User.find_each do |user|
      already_has_token = Doorkeeper::AccessToken.exists?(
        application_id: app.id,
        resource_owner_id: user.id,
        revoked_at: nil
      )
      next if already_has_token

      Doorkeeper::AccessToken.create!(
        application: app,
        resource_owner_id: user.id,
        scopes: 'mcp',
        resource: "#{base_url}/mcp",
        expires_in: nil
      )
    end
  end

  def down
    # Intentionally a no-op: we don't want to mass-revoke tokens that may be in
    # active use just because the migration is rolled back. Revoke individually
    # via `Doorkeeper::AccessToken.by_token(...).revoke!` if needed.
  end
end
