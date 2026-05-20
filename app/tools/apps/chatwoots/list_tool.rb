module Apps
  module Chatwoots
    class ListTool < ApplicationTool
      tool_name 'apps_chatwoots_list'
      description <<~DESC
        List Chatwoot app integrations available in the account. Use the returned id as the app_id
        argument when calling events_send_chatwoot_message. The inboxes field lists the valid
        chatwoot_inbox_id values for that integration.
      DESC

      arguments do
        optional(:id).filled(:integer).description('Filter by integration ID')
        optional(:name).filled(:string).description('Filter by integration name (case-insensitive partial match)')
        optional(:status).filled(:string).description('Filter by status: active, inactive, sync or pair')
        optional(:chatwoot_endpoint_url).filled(:string).description('Filter by chatwoot endpoint URL (partial match)')
        optional(:chatwoot_account_id).filled(:integer).description('Filter by chatwoot account ID')
        optional(:created_from).filled(:string).description('Created on/after this ISO8601 UTC datetime')
        optional(:created_to).filled(:string).description('Created on/before this ISO8601 UTC datetime')
        optional(:updated_from).filled(:string).description('Updated on/after this ISO8601 UTC datetime')
        optional(:updated_to).filled(:string).description('Updated on/before this ISO8601 UTC datetime')
        optional(:page).filled(:integer).description('Page number (default 1)')
        optional(:per_page).filled(:integer).description('Items per page (default 25, max 100)')
      end

      def call(id: nil, name: nil, status: nil, chatwoot_endpoint_url: nil, chatwoot_account_id: nil,
               created_from: nil, created_to: nil, updated_from: nil, updated_to: nil,
               page: 1, per_page: 25)
        handle_with_exception do
          scope = ::Apps::Chatwoot.all
          scope = scope.where(id: id) if id.present?
          scope = scope.where('name ILIKE ?', "%#{name}%") if name.present?
          scope = scope.where(status: status) if status.present?
          scope = scope.where('chatwoot_endpoint_url ILIKE ?', "%#{chatwoot_endpoint_url}%") if chatwoot_endpoint_url.present?
          scope = scope.where(chatwoot_account_id: chatwoot_account_id) if chatwoot_account_id.present?
          scope = scope.where('created_at >= ?', created_from) if created_from.present?
          scope = scope.where('created_at <= ?', created_to) if created_to.present?
          scope = scope.where('updated_at >= ?', updated_from) if updated_from.present?
          scope = scope.where('updated_at <= ?', updated_to) if updated_to.present?

          records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
          {
            data: records.as_json(only: %i[id name status chatwoot_endpoint_url chatwoot_account_id
                                           inboxes created_at updated_at]),
            pagination: pagination
          }.to_json
        end
      end
    end
  end
end
