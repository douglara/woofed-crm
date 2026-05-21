# frozen_string_literal: true

module Oauth
  # RFC 7591 — OAuth 2.0 Dynamic Client Registration Protocol.
  #
  # Lets MCP clients (Claude Web, ChatGPT, Cursor, ...) self-register without
  # any human pre-provisioning. Registration only mints client_id/client_secret;
  # actual data access still requires the human consent flow at /oauth/authorize.
  #
  # Rate-limited at 10 calls per IP per hour to prevent the oauth_applications
  # table from being abused as an unbounded write target.
  class ClientRegistrationsController < ActionController::API
    REGISTRATION_LIMIT = 10
    REGISTRATION_WINDOW = 1.hour

    def create
      return render_error(415, 'invalid_request', 'Content-Type must be application/json') unless json_request?
      return render_error(429, 'rate_limited',    'Too many registration attempts')         if rate_limited?

      redirect_uris = Array(params[:redirect_uris]).compact_blank
      return render_error(400, 'invalid_redirect_uri', 'redirect_uris is required') if redirect_uris.empty?

      application = Doorkeeper::Application.create(
        name:         params[:client_name].presence || 'MCP Client',
        redirect_uri: redirect_uris.join("\n"),
        scopes:       Doorkeeper.config.default_scopes.to_s,
        confidential: true
      )

      return render_validation_error(application) unless application.persisted?

      bump_rate_limit
      render json: registration_response(application, redirect_uris), status: :created
    end

    private

    def json_request?
      request.content_type.to_s.start_with?('application/json')
    end

    def rate_limit_key
      "oauth:dcr:#{request.remote_ip}"
    end

    def rate_limited?
      Rails.cache.read(rate_limit_key).to_i >= REGISTRATION_LIMIT
    end

    def bump_rate_limit
      count = Rails.cache.read(rate_limit_key).to_i + 1
      Rails.cache.write(rate_limit_key, count, expires_in: REGISTRATION_WINDOW)
    end

    def registration_response(application, redirect_uris)
      {
        client_id:                application.uid,
        client_secret:            application.plaintext_secret,
        client_id_issued_at:      application.created_at.to_i,
        client_name:              application.name,
        redirect_uris:            redirect_uris,
        grant_types:              %w[authorization_code refresh_token],
        response_types:           ['code'],
        token_endpoint_auth_method: 'client_secret_basic',
        scope:                    application.scopes.to_s
      }
    end

    def render_validation_error(application)
      error = application.errors.attribute_names.include?(:redirect_uri) ? 'invalid_redirect_uri' : 'invalid_client_metadata'
      render_error(400, error, application.errors.full_messages.join(', '))
    end

    def render_error(status, error, description)
      render json: { error: error, error_description: description }, status: status
    end
  end
end
