# frozen_string_literal: true

class Users::JsonWebToken
  SECRET_KEY = Rails.application.secrets.secret_key_base.to_s

  def self.encode_user(user, expires_in: nil, audience: nil)
    payload = { sub: user.id }
    payload[:exp] = expires_in.from_now.to_i if expires_in
    payload[:aud] = audience if audience
    JWT.encode(payload, SECRET_KEY)
  end

  def self.encode_embed(user, expires_in: 8.hours)
    encode_user(user, expires_in:, audience: 'embed')
  end

  def self.decode_user(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    user = User.find(decoded['sub'])
    { ok: user }
  rescue StandardError => e
    { error: e }
  end

  def self.decode_embed(token)
    decoded = JWT.decode(
      token, SECRET_KEY, true,
      { verify_expiration: true, aud: 'embed', verify_aud: true }
    )[0]
    user = User.find(decoded['sub'])
    { ok: user }
  rescue JWT::ExpiredSignature
    { error: :expired }
  rescue StandardError => e
    { error: e }
  end
end
