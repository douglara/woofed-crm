module Pipeline::Broadcastable
  extend ActiveSupport::Concern
  included do
    after_update_commit do
      deals.find_each do |deal|
        broadcast_update_later_to deal, html: name, target: 'broadcast_pipeline_name'
      end
    end
  end
end
