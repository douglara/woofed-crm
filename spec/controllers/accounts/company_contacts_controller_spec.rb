require 'rails_helper'

RSpec.describe Accounts::CompanyContactsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:company) { create(:company) }
  let!(:contact) { create(:contact) }
  let(:company_contact_last) { CompanyContact.last }

  # The create stream appends to the list of whichever record the link was created
  # from (the company page or the contact page) and closes the modal it came from.
  def append_stream_tag(owner)
    target = ActionView::RecordIdentifier.dom_id(owner, :company_contacts)
    %(<turbo-stream action="append" target="#{target}">)
  end

  def close_modal_stream_tag
    '<turbo-stream action="replace" target="modal">'
  end

  def remove_stream_tag(record)
    %(<turbo-stream action="remove" target="#{ActionView::RecordIdentifier.dom_id(record)}">)
  end

  describe 'POST /accounts/{account.id}/company_contacts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/accounts/#{account.id}/company_contacts",
               params: { company_contact: { company_id: company.id, contact_id: contact.id } }
        end.not_to change(CompanyContact, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        { origin: 'company', company_contact: { company_id: company.id, contact_id: contact.id } }
      end

      before do
        sign_in(user)
      end

      context 'when the origin is the company page' do
        it 'links the contact, appends it to the company contacts list and closes the modal' do
          expect do
            post "/accounts/#{account.id}/company_contacts", params:, as: :turbo_stream
          end.to change(CompanyContact, :count).by(1)
          expect(response).to have_http_status(:ok)
          expect(company_contact_last.company).to eq(company)
          expect(company_contact_last.contact).to eq(contact)
          expect(response.body).to include(append_stream_tag(company))
          expect(response.body).to include(close_modal_stream_tag)
          expect(response.body).to include('<turbo-stream action="replace" target="flash_message">')
          expect(response.body).to include(I18n.t('flash_messages.added', model: Contact.model_name.human))
          expect(response.body).to include(contact.full_name)
        end
      end

      context 'when the origin is the contact page' do
        let(:params) do
          { origin: 'contact', company_contact: { company_id: company.id, contact_id: contact.id } }
        end

        it 'links the company, appends it to the contact companies list and closes the modal' do
          expect do
            post "/accounts/#{account.id}/company_contacts", params:, as: :turbo_stream
          end.to change(CompanyContact, :count).by(1)
          expect(response).to have_http_status(:ok)
          expect(company_contact_last.company).to eq(company)
          expect(company_contact_last.contact).to eq(contact)
          expect(response.body).to include(append_stream_tag(contact))
          expect(response.body).to include(close_modal_stream_tag)
          expect(response.body).to include(I18n.t('flash_messages.added', model: Company.model_name.human))
          expect(response.body).to include(ERB::Util.html_escape(company.name))
        end
      end

      context 'when the origin is not passed' do
        let(:params) do
          { company_contact: { company_id: company.id, contact_id: contact.id } }
        end

        it 'falls back to the company page' do
          expect do
            post "/accounts/#{account.id}/company_contacts", params:, as: :turbo_stream
          end.to change(CompanyContact, :count).by(1)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include(append_stream_tag(company))
          expect(response.body).to include(close_modal_stream_tag)
          expect(response.body).to include(contact.full_name)
        end
      end

      context 'when the link fails' do
        it 'when the contact is already linked to the company' do
          create(:company_contact, company:, contact:)
          expect do
            post "/accounts/#{account.id}/company_contacts", params:
          end.to change(CompanyContact, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('has already been taken')
        end

        it 'when the contact is missing' do
          params = { origin: 'company', company_contact: { company_id: company.id, contact_id: '' } }
          expect do
            post "/accounts/#{account.id}/company_contacts", params:
          end.to change(CompanyContact, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include('must exist')
        end
      end
    end
  end

  describe 'DELETE /accounts/{account.id}/company_contacts/{company_contact.id}' do
    let!(:company_contact) { create(:company_contact, company:, contact:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          delete "/accounts/#{account.id}/company_contacts/#{company_contact.id}"
        end.not_to change(CompanyContact, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'unlinks the contact from the company and removes it from the list' do
        expect do
          delete "/accounts/#{account.id}/company_contacts/#{company_contact.id}", as: :turbo_stream
        end.to change(CompanyContact, :count).by(-1)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(remove_stream_tag(company_contact))
        expect(response.body).to include('<turbo-stream action="replace" target="flash_message">')
        expect(response.body).to include(I18n.t('flash_messages.deleted', model: Contact.model_name.human))
      end
    end
  end
end
