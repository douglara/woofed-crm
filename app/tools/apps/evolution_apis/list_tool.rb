# frozen_string_literal: true

module Apps
  module EvolutionApis
    class ListTool < ApplicationTool
      tool_name 'apps_evolution_apis_list'
      description <<~DESC
        List Evolution API (WhatsApp) integrations configured in the account. When called without arguments, returns the first page of all integrations ordered by most-recently created. An account can have multiple WhatsApp instances — each instance is bound to a different phone number, and outgoing messages are sent from that number.
        This is the discovery step for events_send_whatsapp_message: take the returned `id` and pass it as `app_id`. When the user mentions a specific sender number (e.g. "send from +5511…"), pass it as the `phone` filter (E.164, partial match) to find the right instance before sending.
        Messages are only delivered through an instance whose `connection_status` is `connected` — the others (`disconnected`, `connecting`, `sync`) cannot send. Prefer filtering by `connection_status: 'connected'` when picking an instance to send from.
      DESC

      input_schema(
        properties: {
          id:                { type: 'integer', description: 'Filter by integration ID' },
          name:              { type: 'string',  description: 'Filter by integration name (case-insensitive partial match)' },
          phone:             { type: 'string',  description: 'Filter by connected phone in E.164 format (partial match)' },
          connection_status: { type: 'string',  description: 'Filter by connection status: connected, disconnected, connecting or sync' },
          created_from:      { type: 'string',  description: 'Created on/after this ISO8601 UTC datetime' },
          created_to:        { type: 'string',  description: 'Created on/before this ISO8601 UTC datetime' },
          updated_from:      { type: 'string',  description: 'Updated on/after this ISO8601 UTC datetime' },
          updated_to:        { type: 'string',  description: 'Updated on/before this ISO8601 UTC datetime' },
          page:              { type: 'integer', description: 'Page number (default 1)' },
          per_page:          { type: 'integer', description: 'Items per page (default 25, max 100)' }
        }
      )

      def self.call(server_context:, id: nil, name: nil, phone: nil, connection_status: nil,
                    created_from: nil, created_to: nil, updated_from: nil, updated_to: nil,
                    page: 1, per_page: 25)
        handle_errors do
          scope = ::Apps::EvolutionApi.all
          scope = scope.where(id: id) if id.present?
          scope = scope.where('name ILIKE ?', "%#{name}%") if name.present?
          scope = scope.where('phone ILIKE ?', "%#{phone}%") if phone.present?
          scope = scope.where(connection_status: connection_status) if connection_status.present?
          scope = scope.where('created_at >= ?', created_from) if created_from.present?
          scope = scope.where('created_at <= ?', created_to)   if created_to.present?
          scope = scope.where('updated_at >= ?', updated_from) if updated_from.present?
          scope = scope.where('updated_at <= ?', updated_to)   if updated_to.present?

          records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
          json_response(
            data: records.as_json(only: %i[id name endpoint_url instance phone active connection_status
                                           created_at updated_at]),
            pagination: pagination
          )
        end
      end
    end
  end
end
