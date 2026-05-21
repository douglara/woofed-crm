# frozen_string_literal: true

# RFC 8707 Resource Indicators — binds OAuth grants and access tokens to a
# specific resource URL (e.g. https://app.woofedcrm.com/mcp), so a token issued
# for one resource cannot be used against another.
class AddResourceToOauthTables < ActiveRecord::Migration[7.1]
  def change
    add_column :oauth_access_grants, :resource, :string
    add_column :oauth_access_tokens, :resource, :string
    add_index  :oauth_access_tokens, :resource
  end
end
