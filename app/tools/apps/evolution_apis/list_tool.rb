module Apps
  module EvolutionApis
    class ListTool < ApplicationTool
      tool_name 'apps_evolution_apis_list'
      description <<~DESC
        List Evolution API (WhatsApp) integrations available in the account. Use the returned id as
        the app_id argument when calling events_send_whatsapp_message.
      DESC

      arguments do
        optional(:id).filled(:integer).description('Filter by integration ID')
        optional(:name).filled(:string).description('Filter by integration name (case-insensitive partial match)')
        optional(:phone).filled(:string).description('Filter by connected phone in E.164 format, e.g. +5511999999999 (partial match)')
        optional(:connection_status).filled(:string).description('Filter by connection status: connected, disconnected, connecting or sync')
        optional(:created_from).filled(:string).description('Created on/after this ISO8601 UTC datetime')
        optional(:created_to).filled(:string).description('Created on/before this ISO8601 UTC datetime')
        optional(:updated_from).filled(:string).description('Updated on/after this ISO8601 UTC datetime')
        optional(:updated_to).filled(:string).description('Updated on/before this ISO8601 UTC datetime')
        optional(:page).filled(:integer).description('Page number (default 1)')
        optional(:per_page).filled(:integer).description('Items per page (default 25, max 100)')
      end

      def call(id: nil, name: nil, phone: nil, connection_status: nil,
               created_from: nil, created_to: nil, updated_from: nil, updated_to: nil,
               page: 1, per_page: 25)
        handle_with_exception do
          scope = ::Apps::EvolutionApi.all
          scope = scope.where(id: id) if id.present?
          scope = scope.where('name ILIKE ?', "%#{name}%") if name.present?
          scope = scope.where('phone ILIKE ?', "%#{phone}%") if phone.present?
          scope = scope.where(connection_status: connection_status) if connection_status.present?
          scope = scope.where('created_at >= ?', created_from) if created_from.present?
          scope = scope.where('created_at <= ?', created_to) if created_to.present?
          scope = scope.where('updated_at >= ?', updated_from) if updated_from.present?
          scope = scope.where('updated_at <= ?', updated_to) if updated_to.present?

          records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
          {
            data: records.as_json(only: %i[id name endpoint_url instance phone active connection_status
                                           created_at updated_at]),
            pagination: pagination
          }.to_json
        end
      end
    end
  end
end
