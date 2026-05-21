module Mcp
  class JwtAuthenticator
    UNAUTHORIZED_BODY = { jsonrpc: '2.0', error: { code: -32_001, message: 'Unauthorized' }, id: nil }.to_json.freeze
    REALM = 'Woofed CRM MCP'

    def initialize(app, path_prefix: '/mcp')
      @app = app
      @path_prefix = path_prefix
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      return @app.call(env) unless request.path.start_with?(@path_prefix)

      user = Users::JsonWebToken.decode_user(extract_token(request))[:ok]
      return unauthorized(request) unless user

      Current.set(user: user) { @app.call(env) }
    end

    private

    def extract_token(request)
      token, = ActionController::HttpAuthentication::Token.token_and_options(request)
      token
    end

    # RFC 9728 §5.1: a protected resource returning 401 advertises its
    # authorization server via WWW-Authenticate. MCP clients use this to
    # bootstrap OAuth — without it, Claude Web has no way to discover
    # /.well-known/oauth-protected-resource.
    def unauthorized(request)
      metadata_url = "#{request.base_url}/.well-known/oauth-protected-resource"
      [
        401,
        {
          'Content-Type'     => 'application/json',
          'WWW-Authenticate' => %(Bearer realm="#{REALM}", resource_metadata="#{metadata_url}")
        },
        [UNAUTHORIZED_BODY]
      ]
    end
  end
end
