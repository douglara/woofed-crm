module Contacts
  class UpdateTool < ApplicationTool
    tool_name 'contacts_update'
    description 'Update an existing contact by ID. Only fields provided will be changed.'

    arguments do
      required(:id).filled(:integer).description('Contact ID')
      optional(:full_name).filled(:string).description('Contact full name')
      optional(:email).filled(:string).description('Contact email')
      optional(:phone).filled(:string).description('Contact phone in E.164 format')
      optional(:label_list).array(:string).description('Replace tags applied to the contact')
      optional(:custom_attributes).hash.description('Free-form custom fields as key/value pairs')
    end

    def call(id:, **attributes)
      handle_with_exception do
        contact = Contact.find(id)
        if contact.update(attributes.compact)
          contact.to_json
        else
          unprocessable_error(contact.errors.full_messages)
        end
      end
    end
  end
end
