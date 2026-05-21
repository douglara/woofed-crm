# frozen_string_literal: true

module Apps
  module Chatwoots
    class ListTool < ApplicationTool
      tool_name 'apps_chatwoots_list'
      description <<~DESC
        List Chatwoot app integrations available in the account. Use the returned id as the app_id
        argument when calling events_send_chatwoot_message. The inboxes field lists the valid
        chatwoot_inbox_id values for that integration.
      DESC

      input_schema(
        properties: {
          id:                    { type: 'integer', description: 'Filter by integration ID' },
          name:                  { type: 'string',  description: 'Filter by integration name (case-insensitive partial match)' },
          status:                { type: 'string',  description: 'Filter by status: active, inactive, sync or pair' },
          chatwoot_endpoint_url: { type: 'string',  description: 'Filter by chatwoot endpoint URL (partial match)' },
          chatwoot_account_id:   { type: 'integer', description: 'Filter by chatwoot account ID' },
          created_from:          { type: 'string',  description: 'Created on/after this ISO8601 UTC datetime' },
          created_to:            { type: 'string',  description: 'Created on/before this ISO8601 UTC datetime' },
          updated_from:          { type: 'string',  description: 'Updated on/after this ISO8601 UTC datetime' },
          updated_to:            { type: 'string',  description: 'Updated on/before this ISO8601 UTC datetime' },
          page:                  { type: 'integer', description: 'Page number (default 1)' },
          per_page:              { type: 'integer', description: 'Items per page (default 25, max 100)' }
        }
      )

      def self.call(server_context:, id: nil, name: nil, status: nil, chatwoot_endpoint_url: nil,
                    chatwoot_account_id: nil, created_from: nil, created_to: nil,
                    updated_from: nil, updated_to: nil, page: 1, per_page: 25)
        handle_errors do
          scope = ::Apps::Chatwoot.all
          scope = scope.where(id: id) if id.present?
          scope = scope.where('name ILIKE ?', "%#{name}%") if name.present?
          scope = scope.where(status: status) if status.present?
          scope = scope.where('chatwoot_endpoint_url ILIKE ?', "%#{chatwoot_endpoint_url}%") if chatwoot_endpoint_url.present?
          scope = scope.where(chatwoot_account_id: chatwoot_account_id) if chatwoot_account_id.present?
          scope = scope.where('created_at >= ?', created_from) if created_from.present?
          scope = scope.where('created_at <= ?', created_to)   if created_to.present?
          scope = scope.where('updated_at >= ?', updated_from) if updated_from.present?
          scope = scope.where('updated_at <= ?', updated_to)   if updated_to.present?

          records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
          json_response(
            data: records.as_json(only: %i[id name status chatwoot_endpoint_url chatwoot_account_id
                                           inboxes created_at updated_at]),
            pagination: pagination
          )
        end
      end
    end
  end
end
