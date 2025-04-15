require 'rails_helper'

RSpec.describe Accounts::ContactsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:contact) { create(:contact, account:) }

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

  context 'POST #create' do
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

          expect(response.body).to include('Phone (cell) is invalid')
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'when phone starts with +0' do
          params = { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '+052299881378888889',
                                account_id: account.id } }

          expect do
            post "/accounts/#{account.id}/contacts", params:
          end.to change(Contact, :count).by(0)

          expect(response.body).to include('Phone (cell) is invalid')
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'when phone doesnt start with +' do
          params = { contact: { full_name: 'Yukio Arie', email: 'yukioarie@gmail.com', phone: '052299881378888889',
                                account_id: account.id } }

          expect do
            post "/accounts/#{account.id}/contacts", params:
          end.to change(Contact, :count).by(0)

          expect(response.body).to include('Phone (cell) is invalid')
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  context 'GET #show' do
    before do
      sign_in(user)
    end

    it 'should list contacts' do
      get "/accounts/#{account.id}/contacts"
      expect(response).to have_http_status(200)
      expect(response.body).to include(contact.full_name)
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
end
