module User::WoofedAiTokenMinter
  extend ActiveSupport::Concern

  WOOFED_AI_APP_NAME = 'Woofed AI'

  included do
    # Mints the Doorkeeper access token (scope `mcp`) the Python agent uses to
    # call /mcp on this user's behalf. Pre-existing users are seeded by
    # db/migrate/..._backfill_woofed_ai_tokens_for_users.rb.
    after_create :generate_woofed_ai_token
  end

  private

  def generate_woofed_ai_token
    base_url = ENV['FRONTEND_URL']&.chomp('/')
    raise 'FRONTEND_URL is required to mint the Woofed AI access token' if base_url.blank?

    app = Doorkeeper::Application.find_or_create_by!(name: 'Woofed AI') do |a|
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
