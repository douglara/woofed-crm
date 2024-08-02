Rails.application.configure do
  config.x.vapid.private_key = ENV.fetch('VAPID_PRIVATE_KEY', Rails.application.credentials.dig(:vapid, :private_key))
  config.x.vapid.public_key = ENV.fetch('VAPID_PUBLIC_KEY', Rails.application.credentials.dig(:vapid, :public_key))
end
