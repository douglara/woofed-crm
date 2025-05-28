require 'rails_helper'

RSpec.describe Accounts::ContactsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:contact) { create(:contact, account:) }

  context 'POST /accounts/{account.id}/contacts' do
    context 'when it is an unauthenticated user' do
      let!(:params) do
        { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '+5522998813788',
                     account_id: account.id } }
      end

      it 'returns unauthorized' do
        expect { post "/accounts/#{account.id}/contacts", params: }.not_to change(Contact, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      let!(:params) do
        { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '+5522998813788',
                     account_id: account.id } }
      end

      it 'create contact' do
        expect do
          post "/accounts/#{account.id}/contacts", params:
        end.to change(Contact, :count).by(1)

        expect(response).to have_http_status(302)
      end

      context 'not create a new contact' do
        context 'when phone is invalid' do
          it 'when phone is more than 15 characters' do
            params = { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '+552299881378888889',
                                  account_id: account.id } }

            expect do
              post "/accounts/#{account.id}/contacts", params:
            end.to change(Contact, :count).by(0)

            expect(response.body).to include('must be in e164 format')
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end
    end
  end

  context 'GET /accounts/{account.id}/contacts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/contacts"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'should list contacts' do
        get "/accounts/#{account.id}/contacts"
        expect(response).to have_http_status(200)
        doc = Nokogiri::HTML(response.body)
        table_body = doc.at_css('tbody#contacts').text
        expect(table_body).to include(contact.full_name)
      end

      context 'when query params are present' do
        context 'when query params match with contact full_name' do
          it 'returns contacts on contacts table' do
            get "/accounts/#{account.id}/contacts", params: { query: contact.full_name }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Contacts')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#contacts').text
            expect(table_body).to include(ERB::Util.html_escape(contact.full_name))
            expect(table_body).to include(contact.email)
            expect(table_body).to include(contact.phone)
            expect(table_body).to include(contact.id.to_s)
          end
        end

        context 'when query params match with contact email' do
          it 'returns contacts on contacts table' do
            get "/accounts/#{account.id}/contacts", params: { query: contact.email }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Contacts')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#contacts').text
            expect(table_body).to include(ERB::Util.html_escape(contact.full_name))
            expect(table_body).to include(contact.email)
            expect(table_body).to include(contact.phone)
            expect(table_body).to include(contact.id.to_s)
          end
        end

        context 'when query params match with contact phone' do
          it 'returns contacts on contacts table' do
            get "/accounts/#{account.id}/contacts", params: { query: contact.phone }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Contacts')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#contacts').text
            expect(table_body).to include(ERB::Util.html_escape(contact.full_name))
            expect(table_body).to include(contact.email)
            expect(table_body).to include(contact.phone)
            expect(table_body).to include(contact.id.to_s)
          end
        end

        context 'when query params match partially with contact full_name' do
          let(:first_name) { contact.full_name.split.first }
          it 'returns contacts with partial match' do
            get "/accounts/#{account.id}/contacts", params: { query: first_name }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Contacts')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#contacts').text
            expect(table_body).to include(ERB::Util.html_escape(contact.full_name))
            expect(table_body).to include(contact.email)
            expect(table_body).to include(contact.phone)
            expect(table_body).to include(contact.id.to_s)
          end
        end

        context 'when query params are case-insensitive' do
          it 'returns contacts regardless of case' do
            get "/accounts/#{account.id}/contacts", params: { query: contact.full_name.swapcase }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Contacts')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#contacts').text
            expect(table_body).to include(ERB::Util.html_escape(contact.full_name))
            expect(table_body).to include(contact.email)
            expect(table_body).to include(contact.phone)
            expect(table_body).to include(contact.id.to_s)
          end
        end

        context 'when query params do not match any contacts' do
          it 'returns an empty contacts table' do
            get "/accounts/#{account.id}/contacts", params: { query: 'NonexistentContact123' }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Contacts')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#contacts').text
            expect(table_body).not_to include(ERB::Util.html_escape(contact.full_name))
            expect(table_body).not_to include(contact.email)
            expect(table_body).not_to include(contact.phone)
            expect(table_body).not_to include(contact.id.to_s)
          end
        end

        context 'when there are multiple contacts and query does not match any' do
          let!(:contact2) do
            create(:contact, account:, full_name: 'Jane Smith', email: 'jane.smith@example.com',
                             phone: '+55226598745699')
          end
          let!(:contact3) do
            create(:contact, account:, full_name: 'Bob Johnson', email: 'bob.johnson@example.com',
                             phone: '+5541225695285')
          end

          it 'returns an empty contacts table' do
            get "/accounts/#{account.id}/contacts", params: { query: 'NonexistentContact123' }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Contacts')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#contacts').text
            expect(table_body).not_to include(ERB::Util.html_escape(contact.full_name))
            expect(table_body).not_to include(ERB::Util.html_escape(contact2.full_name))
            expect(table_body).not_to include(ERB::Util.html_escape(contact3.full_name))
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/contacts/{contact.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/contacts/#{contact.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let!(:contact2) { create(:contact, account:) }
      let!(:pipeline) { create(:pipeline, account:) }
      let!(:stage) { create(:stage, account:, pipeline:) }
      let!(:deal) { create(:deal, account:, stage:, contact:) }

      before do
        sign_in(user)
      end

      context 'get contact' do
        it 'get contact by account' do
          get "/accounts/#{account.id}/contacts/#{contact.id}"
          expect(response.body).to include(ERB::Util.html_escape(contact.full_name))
          expect(response.body).to include(ERB::Util.html_escape(contact.email))
          expect(response.body).to include(ERB::Util.html_escape(deal.name))
          expect(response.body).not_to include('chatwoot_conversation_link')
        end
        context 'when there is chatwoot integration' do
          let!(:chatwoot) { create(:apps_chatwoots, account:, chatwoot_account_id: '456', chatwoot_endpoint_url: 'https://chatwoot.example.com/') }

          before do
            user.reload
          end

          it 'should show chatwoot conversation link button' do
            get "/accounts/#{account.id}/contacts/#{contact.id}"
            expect(response.body).to include('chatwoot_conversation_link')
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/contacts/select_contact_search?query=query' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/contacts/select_contact_search?query=query"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'select contact search component' do
        it do
          get "/accounts/#{account.id}/contacts/select_contact_search"
          expect(response).to have_http_status(200)
        end
        context 'when there is query parameter' do
          it 'should return contact' do
            get "/accounts/#{account.id}/contacts/select_contact_search?query=#{contact.full_name}"
            expect(response).to have_http_status(200)

            html = Nokogiri::HTML(response.body)
            contact_list_frame = html.at_css('turbo-frame#select_contact_results').text
            expect(contact_list_frame).to include(contact.full_name)
          end

          context 'when query parameter is not found' do
            it 'should return 0 contacts' do
              get "/accounts/#{account.id}/contacts/select_contact_search?query=teste"
              expect(response).to have_http_status(200)

              html = Nokogiri::HTML(response.body)
              contact_list_frame = html.at_css('turbo-frame#select_contact_results').text
              expect(contact_list_frame).not_to include(contact.full_name)
              expect(contact_list_frame.strip.empty?).to be_truthy
            end
          end
        end
        context 'when there is a form_name parameter' do
          it 'should render form_name as hidden_field_name on html form' do
            get "/accounts/#{account.id}/contacts/select_contact_search",
                params: { form_name: 'deal[contact_id]' }

            expect(response).to have_http_status(200)
            expect(response.body).to include('deal[contact_id]')
          end
        end

        context 'when there is no form_name parameter' do
          it 'should not render a specific hidden_field_name on html form' do
            get "/accounts/#{account.id}/contacts/select_contact_search"

            expect(response).to have_http_status(200)
            expect(response.body).not_to include('deal[contact_id]')
          end
        end

        context 'when there is a content_value parameter' do
          it 'should render content_value as selected_model_name on html form' do
            get "/accounts/#{account.id}/contacts/select_contact_search",
                params: { content_value: 'contact_name_test' }

            expect(response).to have_http_status(200)
            expect(response.body).to include('contact_name_test')
            expect(response.body).not_to include('Search contact')
          end
        end

        context 'when there is no content_value parameter' do
          it 'should render the default search placeholder instead of a selected name' do
            get "/accounts/#{account.id}/contacts/select_contact_search"

            expect(response).to have_http_status(200)
            expect(response.body).not_to include('contact_name_test')
            expect(response.body).to include('Search contact')
          end
        end

        context 'when there is a form_id parameter' do
          it 'should render form_id as hidden_field_value on html form' do
            get "/accounts/#{account.id}/contacts/select_contact_search",
                params: { form_id: '101' }

            expect(response).to have_http_status(200)
            expect(response.body).to include('value="101"')
          end
        end

        context 'when there is no form_id parameter' do
          it 'should not render a specific id in the hidden field' do
            get "/accounts/#{account.id}/contacts/select_contact_search"

            expect(response).to have_http_status(200)
            expect(response.body).not_to include('value="101"')
          end
        end

        context 'when all parameters are present' do
          it 'should render all parameters correctly in the HTML form' do
            get "/accounts/#{account.id}/contacts/select_contact_search",
                params: {
                  form_name: 'deal[contact_id]',
                  content_value: 'contact_name_test',
                  form_id: '101'
                }

            expect(response).to have_http_status(200)
            expect(response.body).to include('deal[contact_id]')
            expect(response.body).to include('contact_name_test')
            expect(response.body).to include('value="101"')
            expect(response.body).not_to include('Search contact')
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/contacts/{contact.id}/chatwoot_conversation_link' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/contacts/#{contact.id}/chatwoot_conversation_link"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'get contact conversation link by account' do
        context 'when the Chatwoot conversation link is successfully generated' do
          let(:link) { 'https://chatwoot.example.com/app/accounts/456/conversations/789' }

          before do
            allow(Contact::Integrations::Chatwoot::GenerateConversationLink).to receive(:new)
              .with(contact)
              .and_return(double(call: { ok: link }))
          end

          it 'assigns the conversation link and sets no error' do
            get "/accounts/#{account.id}/contacts/#{contact.id}/chatwoot_conversation_link"
            expect(response).to have_http_status(200)
            expect(response.body).to include('Go to the last conversation')
            expect(response.body).to include(link)
          end
        end
        context 'when the Chatwoot conversation link is not generated successfully' do
          context 'when GenerateConversationLink returns error' do
            before do
              allow(Contact::Integrations::Chatwoot::GenerateConversationLink).to receive(:new)
                .with(contact)
                .and_return(double(call: { error: 'no_chatwoot_or_id' }))
            end

            it 'assigns nil to chatwoot_conversation_link and sets the error' do
              get "/accounts/#{account.id}/contacts/#{contact.id}/chatwoot_conversation_link"
              expect(response).to have_http_status(200)
              expect(response.body).to include('No conversations for this contact')
            end
          end
          context 'when GenerateConversationLink raises a Faraday::TimeoutError' do
            before do
              allow(Contact::Integrations::Chatwoot::GenerateConversationLink).to receive(:new)
                .with(contact)
                .and_raise(Faraday::TimeoutError)
            end

            it 'sets chatwoot_conversation_link to nil and connection_error to true' do
              get "/accounts/#{account.id}/contacts/#{contact.id}/chatwoot_conversation_link"
              expect(response).to have_http_status(200)
              expect(response.body).to include('Could not connect. Please try again.')
            end
          end
        end
      end
    end
  end
  describe 'GET /accounts/{account.id}/contacts/{contact.id}/hovercard_preview' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/contacts/#{contact.id}/hovercard_preview"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'get contact hovercard preview by account' do
        get "/accounts/#{account.id}/contacts/#{contact.id}/hovercard_preview"
        expect(response.body).to include(ERB::Util.html_escape(contact.full_name))
        expect(response.body).to include(ERB::Util.html_escape(contact.email))
        expect(response.body).to include(ERB::Util.html_escape(contact.phone))
        expect(response.body).to include("hovercard_preview_contact_#{contact.id}")
      end
    end
  end

  describe 'PACTH /accounts/{account.id}/contacts/{contact.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/contacts/#{contact.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'update contact by account' do
        let(:params) do
          { contact: { full_name: 'Contact Updated Name Test', phone: '+552299881358',
                       email: 'contact-updated-email@email.com', label_list: 'label_test_1, label_test_2', custom_attributes: { 'custom_attribute_teste' => '123456' } } }
        end
        it do
          patch("/accounts/#{account.id}/contacts/#{contact.id}", params:)
          expect(response).to redirect_to(account_contact_path(account, contact))

          expect(contact.reload.full_name).to eq('Contact Updated Name Test')
          expect(contact.phone).to eq('+552299881358')
          expect(contact.email).to eq('contact-updated-email@email.com')
          expect(contact.label_list).to match_array(%w[label_test_1 label_test_2])
          expect(contact.custom_attributes).to eq({ 'custom_attribute_teste' => '123456' })
        end
      end
      context 'should not update contact' do
        context 'when the phone is already used by another contact' do
          let!(:other_contact) { create(:contact, account:, phone: '+123456789') }
          let(:params) { { contact: { phone: '+123456789' } } }

          it 'should return unprocessable_entity' do
            patch("/accounts/#{account.id}/contacts/#{contact.id}", params:)
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end
    end
  end

  context 'DELETE /accounts/{account.id}/contacts/{contact.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/contacts/#{contact.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'delete the contact by account' do
        it do
          expect do
            delete "/accounts/#{account.id}/contacts/#{contact.id}"
          end.to change(Contact, :count).by(-1)
        end
      end
    end
  end

  context 'GET /accounts/{account.id}/contacts/new' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/contacts/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'get contact new page' do
        it do
          get "/accounts/#{account.id}/contacts/new"
          expect(response).to have_http_status(200)
        end
      end
    end
  end
end
