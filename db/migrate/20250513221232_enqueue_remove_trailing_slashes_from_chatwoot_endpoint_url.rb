class EnqueueRemoveTrailingSlashesFromChatwootEndpointUrl < ActiveRecord::Migration[7.1]
  def change
    enqueue_remove_trailing_slashes_from_chatwoot_endpoint_url
  end

  private

  def enqueue_remove_trailing_slashes_from_chatwoot_endpoint_url
    Apps::Chatwoot.find_in_batches do |batch|
      batch.each do |chatwoot|
        Apps::Chatwoot::Migrations::RemoveTrailingSlashesFromChatwootEndpointUrlJob.set(queue: 'migration').perform_later(chatwoot.id)
      end
    end
  end
end
