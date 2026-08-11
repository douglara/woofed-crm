# frozen_string_literal: true

class Apps::Salesforce::Oauth::ExchangeCode
  def self.call(salesforce, code:, code_verifier:)
    Apps::Salesforce::Oauth::TokenRequest.new(
      salesforce,
      grant_type: 'authorization_code',
      code: code,
      client_id: salesforce.client_id,
      client_secret: salesforce.client_secret,
      redirect_uri: salesforce.redirect_uri,
      code_verifier: code_verifier
    ).call
  end
end
