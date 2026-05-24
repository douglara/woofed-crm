# frozen_string_literal: true

module Contacts
  class UpdateTool < ApplicationTool
    tool_name 'contacts_update'
    description <<~DESC
      Update an existing contact by ID. Only fields provided are changed; omitted fields are left untouched. Use contacts_list first to discover the contact ID.
      `phone` must be in E.164 format (e.g. `+5511999999999`).
      `label_list` REPLACES the contact's tags wholesale — pass the full desired set, not just the additions. `custom_attributes` is set via Rails `update`, so it replaces the whole JSONB hash; to add a single key, read the current value first via the `woofed:///contacts/{id}` resource.
    DESC

    input_schema(
      properties: {
        id:                { type: 'integer', description: 'Contact ID' },
        full_name:         { type: 'string',  description: 'Contact full name' },
        email:             { type: 'string',  description: 'Contact email' },
        phone:             { type: 'string',  description: 'Contact phone in E.164 format' },
        label_list:        { type: 'array',   items: { type: 'string' }, description: 'Replace tags applied to the contact' },
        custom_attributes: { type: 'object',  description: 'Free-form custom fields as key/value pairs' }
      },
      required: ['id']
    )

    def self.call(server_context:, id:, full_name: nil, email: nil, phone: nil, label_list: nil, custom_attributes: nil)
      handle_errors do
        contact = Contact.find(id)
        attributes = { full_name: full_name, email: email, phone: phone,
                       label_list: label_list, custom_attributes: custom_attributes }.compact
        if contact.update(attributes)
          json_response(contact.as_json)
        else
          text_response("Validation failed: #{contact.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
