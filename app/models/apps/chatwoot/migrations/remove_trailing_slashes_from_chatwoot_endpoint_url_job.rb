class Apps::Chatwoot::Migrations::RemoveTrailingSlashesFromChatwootEndpointUrlJob < ApplicationJob
  self.queue_adapter = :good_job

  def perform(chatwoot_id)
    chatwoot = Apps::Chatwoot.find_by(id: chatwoot_id)
    return unless chatwoot
    return unless chatwoot.chatwoot_endpoint_url.present?

    cleaned_url = chatwoot.chatwoot_endpoint_url.gsub(/\/+\z/, '')
    if chatwoot.chatwoot_endpoint_url != cleaned_url
      chatwoot.update_column(:chatwoot_endpoint_url, cleaned_url)
    end
  end
end
