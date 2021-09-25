class Users::JsonWebToken
  SECRET_KEY = Rails.application.secrets.secret_key_base.to_s

  def self.encode_user(user)
    hmac_secret = SECRET_KEY
    JWT.encode({ sub: user.id }, hmac_secret)
  end

  def self.decode_user(token)
    begin
      decoded = JWT.decode(token, SECRET_KEY)[0]
      user = User.find(decoded["sub"])
      return { ok: user }
    rescue => e
      return { error: e }
    end
  end
end