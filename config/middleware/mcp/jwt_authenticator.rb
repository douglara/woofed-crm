module Mcp
  class JwtAuthenticator
    UNAUTHORIZED_BODY = { jsonrpc: '2.0', error: { code: -32_001, message: 'Unauthorized' }, id: nil }.to_json.freeze

    def initialize(app, path_prefix: '/mcp')
      @app = app
      @path_prefix = path_prefix
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      return @app.call(env) unless request.path.start_with?(@path_prefix)

      user = Users::JsonWebToken.decode_user(extract_token(request))[:ok]
      return unauthorized unless user

      Current.set(user: user) { @app.call(env) }
    end

    private

    def extract_token(request)
      token, = ActionController::HttpAuthentication::Token.token_and_options(request)
      token
    end

    def unauthorized
      [401, { 'Content-Type' => 'application/json' }, [UNAUTHORIZED_BODY]]
    end
  end
end
