module Contacts
  class ListTool < ApplicationTool
    tool_name 'contacts_list'
    description 'List contacts in the account. Supports partial-match filters and pagination.'

    arguments do
      optional(:id).filled(:integer).description('Filter by contact ID')
      optional(:full_name).filled(:string).description('Filter by full_name (case-insensitive partial match)')
      optional(:email).filled(:string).description('Filter by email (case-insensitive partial match)')
      optional(:phone).filled(:string).description('Filter by phone in E.164 format, e.g. +5511999999999 (partial match)')
      optional(:created_from).filled(:string).description('Created on/after this ISO8601 UTC datetime')
      optional(:created_to).filled(:string).description('Created on/before this ISO8601 UTC datetime')
      optional(:updated_from).filled(:string).description('Updated on/after this ISO8601 UTC datetime')
      optional(:updated_to).filled(:string).description('Updated on/before this ISO8601 UTC datetime')
      optional(:custom_attributes).hash.description('Filter by custom_attributes key/value pairs (exact match per key)')
      optional(:page).filled(:integer).description('Page number (default 1)')
      optional(:per_page).filled(:integer).description('Items per page (default 25, max 100)')
    end

    def call(id: nil, full_name: nil, email: nil, phone: nil,
             created_from: nil, created_to: nil, updated_from: nil, updated_to: nil,
             custom_attributes: nil, page: 1, per_page: 25)
      handle_with_exception do
        scope = Contact.all
        scope = scope.where(id: id) if id.present?
        scope = scope.where('full_name ILIKE ?', "%#{full_name}%") if full_name.present?
        scope = scope.where('email ILIKE ?', "%#{email}%") if email.present?
        scope = scope.where('phone ILIKE ?', "%#{phone}%") if phone.present?
        scope = scope.where('created_at >= ?', created_from) if created_from.present?
        scope = scope.where('created_at <= ?', created_to) if created_to.present?
        scope = scope.where('updated_at >= ?', updated_from) if updated_from.present?
        scope = scope.where('updated_at <= ?', updated_to) if updated_to.present?
        custom_attributes&.each do |key, value|
          scope = scope.where('custom_attributes->>? = ?', key.to_s, value.to_s)
        end

        records, pagination = paginate(scope.order(created_at: :desc), page: page, per_page: per_page)
        {
          data: records.as_json(only: %i[id full_name email phone custom_attributes additional_attributes created_at updated_at]),
          pagination: pagination
        }.to_json
      end
    end
  end
end
