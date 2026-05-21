# frozen_string_literal: true

module Contacts
  class CreateTool < ApplicationTool
    tool_name 'contacts_create'
    description 'Create a new contact. Provide at least one of email or phone so it can be matched later.'

    input_schema(
      properties: {
        full_name:         { type: 'string', description: 'Contact full name' },
        email:             { type: 'string', description: 'Contact email' },
        phone:             { type: 'string', description: 'Contact phone in E.164 format, e.g. +5511999999999' },
        label_list:        { type: 'array',  items: { type: 'string' }, description: 'Tags to apply to the contact' },
        custom_attributes: { type: 'object', description: 'Free-form custom fields as key/value pairs' }
      }
    )

    def self.call(server_context:, full_name: nil, email: nil, phone: nil, label_list: nil, custom_attributes: nil)
      handle_errors do
        attributes = { full_name: full_name, email: email, phone: phone,
                       label_list: label_list, custom_attributes: custom_attributes }.compact
        contact = Contact.new(attributes)
        if contact.save
          json_response(contact.as_json)
        else
          text_response("Validation failed: #{contact.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
