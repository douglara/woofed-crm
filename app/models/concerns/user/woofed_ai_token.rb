module User::WoofedAiToken
  extend ActiveSupport::Concern

  WOOFED_AI_APP_NAME = 'Woofed AI'

  included do
    # Mints the Doorkeeper access token (scope `mcp`) the Python agent uses to
    # call /mcp on this user's behalf. Pre-existing users are seeded by
    # db/migrate/..._backfill_woofed_ai_tokens_for_users.rb.
    after_create :generate_woofed_ai_token
  end

  # Returns the active Woofed AI access token string the Python agent uses to
  # authenticate against /mcp on this user's behalf. This is the value sent as
  # `factory_input.mcp_token` when calling the agent. Returns nil when the user
  # has no active token.
  def woofed_ai_token
    access_tokens
      .where(revoked_at: nil)
      .joins(:application)
      .find_by(oauth_applications: { name: WOOFED_AI_APP_NAME })
      &.token
  end

  private

  def generate_woofed_ai_token
    base_url = ENV['FRONTEND_URL']&.chomp('/')
    raise 'FRONTEND_URL is required to mint the Woofed AI access token' if base_url.blank?

    app = Doorkeeper::Application.find_or_create_by!(name: WOOFED_AI_APP_NAME) do |a|
      a.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
      a.scopes = 'mcp'
      a.confidential = true
    end

    Doorkeeper::AccessToken.create!(
      application: app,
      resource_owner_id: id,
      scopes: 'mcp',
      resource: "#{base_url}/mcp",
      expires_in: nil
    )
  end
end
