module Contacts
  class CreateTool < ApplicationTool
    tool_name 'contacts_create'
    description 'Create a new contact. Provide at least one of email or phone so it can be matched later.'

    arguments do
      optional(:full_name).filled(:string).description('Contact full name')
      optional(:email).filled(:string).description('Contact email')
      optional(:phone).filled(:string).description('Contact phone in E.164 format, e.g. +5511999999999')
      optional(:label_list).array(:string).description('Tags to apply to the contact')
      optional(:custom_attributes).hash.description('Free-form custom fields as key/value pairs')
    end

    def call(**attributes)
      handle_with_exception do
        contact = Contact.new(attributes.compact)
        if contact.save
          contact.to_json
        else
          unprocessable_error(contact.errors.full_messages)
        end
      end
    end
  end
end
