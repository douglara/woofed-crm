# frozen_string_literal: true

# Daily health check. Nothing tells us when a customer revokes the app on the
# Salesforce side, so the connection is exercised on a schedule: the failure then
# surfaces as `status: error` before the next sync runs, instead of as records
# quietly going missing.
class Apps::Salesforce::Connection::Refresh
  def initialize(salesforce)
    @salesforce = salesforce
  end

  def call
    return true unless @salesforce&.connected?

    Apps::Salesforce::Connection::RefreshToken.new(@salesforce, force: true).call
    true
  end
end
