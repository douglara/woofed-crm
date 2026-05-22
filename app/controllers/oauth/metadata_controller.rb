# frozen_string_literal: true

module Oauth
  # Public discovery endpoints used by MCP clients (Claude Web, ChatGPT, etc.)
  # to bootstrap the OAuth 2.1 flow without prior configuration.
  #
  # - RFC 9728: Protected Resource Metadata — points clients to the auth server.
  # - RFC 8414: Authorization Server Metadata — advertises endpoints + capabilities.
  class MetadataController < ActionController::API
    # GET /.well-known/oauth-protected-resource
    def protected_resource
      render json: {
        resource: "#{request.base_url}/mcp",
        authorization_servers: [request.base_url]
      }
    end

    # GET /.well-known/oauth-authorization-server
    # GET /.well-known/openid-configuration
    #
    # ChatGPT (and some other clients) probe /.well-known/openid-configuration
    # during connector setup even when OIDC is not strictly required. Serving
    # the same OAuth metadata at that path satisfies the probe without
    # implementing full OIDC (id_token / userinfo_endpoint).
    def authorization_server
      render json: {
        issuer: request.base_url,
        authorization_endpoint: "#{request.base_url}/oauth/authorize",
        token_endpoint:         "#{request.base_url}/oauth/token",
        revocation_endpoint:    "#{request.base_url}/oauth/revoke",
        introspection_endpoint: "#{request.base_url}/oauth/introspect",
        registration_endpoint:  "#{request.base_url}/oauth/register",
        grant_types_supported:     %w[authorization_code refresh_token],
        response_types_supported:  ['code'],
        token_endpoint_auth_methods_supported: %w[client_secret_basic client_secret_post],
        code_challenge_methods_supported: ['S256'],
        scopes_supported: Doorkeeper.config.scopes.all.map(&:to_s)
      }
    end
  end
end
