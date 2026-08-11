# frozen_string_literal: true

# Active Record Encryption keys. This app has no config/master.key -- every secret
# comes from the environment (see config/secrets.yml) -- so the encryption keys are
# derived from secret_key_base instead of from encrypted credentials.
#
# Consequence: rotating SECRET_KEY_BASE makes encrypted columns unreadable. Only
# re-obtainable third-party credentials are encrypted, never user data, so the
# recovery is reconnecting the integration -- the same path a refresh token
# revoked on the Salesforce side already goes through.
#
# Configured through `on_load` because Active Record is loaded by other
# initializers before this file runs, and by then assigning
# `config.active_record.encryption` no longer has any effect.
secret = Rails.application.secret_key_base

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Encryption.configure(
    primary_key: "#{secret}/primary",
    deterministic_key: "#{secret}/deterministic",
    key_derivation_salt: "#{secret}/salt"
  )
end
