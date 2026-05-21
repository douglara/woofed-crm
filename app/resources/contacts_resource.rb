# frozen_string_literal: true

class ContactsResource < ApplicationResource
  uri_template 'woofed:///contacts/{id}'
  resource_name 'contact'
  description 'A contact record, including its deals and events.'
  mime_type 'application/json'

  def content
    contact = Contact.find(params[:id])
    JSON.generate(contact.as_json(include: %i[deals events]))
  end
end
