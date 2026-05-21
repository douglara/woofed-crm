# frozen_string_literal: true

module Contacts
  class ListTool < ApplicationTool
    tool_name 'contacts_list'
    description 'List contacts in the account. Supports partial-match filters and pagination.'

    input_schema(
      properties: {
        id:                { type: 'integer', description: 'Filter by contact ID' },
        full_name:         { type: 'string',  description: 'Filter by full_name (case-insensitive partial match)' },
        email:             { type: 'string',  description: 'Filter by email (case-insensitive partial match)' },
        phone:             { type: 'string',  description: 'Filter by phone in E.164 format (partial match)' },
        created_from:      { type: 'string',  description: 'Created on/after this ISO8601 UTC datetime' },
        created_to:        { type: 'string',  description: 'Created on/before this ISO8601 UTC datetime' },
        updated_from:      { type: 'string',  description: 'Updated on/after this ISO8601 UTC datetime' },
        updated_to:        { type: 'string',  description: 'Updated on/before this ISO8601 UTC datetime' },
        custom_attributes: { type: 'object',  description: 'Filter by custom_attributes key/value pairs (exact match per key)' },
        page:              { type: 'integer', description: 'Page number (default 1)' },
        per_page:          { type: 'integer', description: 'Items per page (default 25, max 100)' }
      }
    )

    def self.call(server_context:, id: nil, full_name: nil, email: nil, phone: nil,
                  created_from: nil, created_to: nil, updated_from: nil, updated_to: nil,
                  custom_attributes: nil, page: 1, per_page: 25)
      handle_errors do
        scope = Contact.all
        scope = scope.where(id: id) if id.present?
        scope = scope.where('full_name ILIKE ?', "%#{full_name}%") if full_name.present?
        scope = scope.where('email ILIKE ?', "%#{email}%") if email.present?
        scope = scope.where('phone ILIKE ?', "%#{phone}%") if phone.present?
        scope = scope.where('created_at >= ?', created_from) if created_from.present?
        scope = scope.where('created_at <= ?', created_to)   if created_to.present?
        scope = scope.where('updated_at >= ?', updated_from) if updated_from.present?
        scope = scope.where('updated_at <= ?', updated_to)   if updated_to.present?
        custom_attributes&.each do |key, value|
          scope = scope.where('custom_attributes->>? = ?', key.to_s, value.to_s)
        end

        records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
        json_response(
          data: records.as_json(only: %i[id full_name email phone custom_attributes additional_attributes created_at updated_at]),
          pagination: pagination
        )
      end
    end
  end
end
