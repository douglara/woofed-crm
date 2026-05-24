# frozen_string_literal: true

module Users
  class ListTool < ApplicationTool
    tool_name 'users_list'
    description <<~DESC
      List users (members) of the account. When called without arguments, returns the first page of all users ordered by most-recently created.
      Use it either to browse users, or to discover the `user_id` needed by deals_add_assignee / deals_remove_assignee. The full user record with the deals they own is also available via the `woofed:///users/{id}` resource.
      Sensitive fields (encrypted_password, reset tokens, devise tracking columns) are never returned.
    DESC

    input_schema(
      properties: {
        id:              { type: 'integer', description: 'Filter by user ID' },
        full_name:       { type: 'string',  description: 'Filter by full_name (case-insensitive partial match)' },
        email:           { type: 'string',  description: 'Filter by email (case-insensitive partial match)' },
        phone:           { type: 'string',  description: 'Filter by phone in E.164 format (partial match)' },
        job_description: { type: 'string',  description: 'Filter by job_description (exact match, e.g. "ceo", "sales_representative")' },
        language:        { type: 'string',  description: 'Filter by language (exact match, e.g. "en", "pt-BR", "es")' },
        created_from:    { type: 'string',  description: 'Created on/after this ISO8601 UTC datetime' },
        created_to:      { type: 'string',  description: 'Created on/before this ISO8601 UTC datetime' },
        updated_from:    { type: 'string',  description: 'Updated on/after this ISO8601 UTC datetime' },
        updated_to:      { type: 'string',  description: 'Updated on/before this ISO8601 UTC datetime' },
        page:            { type: 'integer', description: 'Page number (default 1)' },
        per_page:        { type: 'integer', description: 'Items per page (default 25, max 100)' }
      }
    )

    def self.call(server_context:, id: nil, full_name: nil, email: nil, phone: nil,
                  job_description: nil, language: nil,
                  created_from: nil, created_to: nil, updated_from: nil, updated_to: nil,
                  page: 1, per_page: 25)
      handle_errors do
        scope = User.all
        scope = scope.where(id: id) if id.present?
        scope = scope.where('full_name ILIKE ?', "%#{full_name}%") if full_name.present?
        scope = scope.where('email ILIKE ?', "%#{email}%") if email.present?
        scope = scope.where('phone ILIKE ?', "%#{phone}%") if phone.present?
        scope = scope.where(job_description: job_description) if job_description.present?
        scope = scope.where(language: language) if language.present?
        scope = scope.where('created_at >= ?', created_from) if created_from.present?
        scope = scope.where('created_at <= ?', created_to)   if created_to.present?
        scope = scope.where('updated_at >= ?', updated_from) if updated_from.present?
        scope = scope.where('updated_at <= ?', updated_to)   if updated_to.present?

        records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
        json_response(
          data: records.as_json(only: %i[id full_name email phone job_description language avatar_url created_at updated_at]),
          pagination: pagination
        )
      end
    end
  end
end
