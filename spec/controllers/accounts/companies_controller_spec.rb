require 'rails_helper'

RSpec.describe Accounts::CompaniesController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:company) { create(:company) }
  let(:company_last) { Company.last }

  def get_file(name)
    Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/files/#{name}")
  end

  describe 'GET /accounts/{account.id}/companies' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/companies"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let!(:company) { create(:company, name: 'Sample Company', email: 'sample@example.com', phone: '+5511999999999') }

      before do
        sign_in(user)
      end

      it 'lists companies' do
        get "/accounts/#{account.id}/companies"
        expect(response).to have_http_status(200)
        table_body = Nokogiri::HTML(response.body).at_css('tbody#companies').text
        expect(table_body).to include(company.name)
        expect(table_body).to include(company.email)
        expect(table_body).to include(company.phone)
      end

      context 'when query params are present' do
        context 'when query params match with company name' do
          it 'returns companies on companies table' do
            get "/accounts/#{account.id}/companies", params: { query: company.name }
            expect(response).to have_http_status(200)
            expect(Nokogiri::HTML(response.body).at_css('tbody#companies').text).to include(company.name)
          end
        end

        context 'when query params match with company email' do
          it 'returns companies on companies table' do
            get "/accounts/#{account.id}/companies", params: { query: company.email }
            expect(response).to have_http_status(200)
            expect(Nokogiri::HTML(response.body).at_css('tbody#companies').text).to include(company.name)
          end
        end

        context 'when query params match with company phone' do
          it 'returns companies on companies table' do
            get "/accounts/#{account.id}/companies", params: { query: company.phone }
            expect(response).to have_http_status(200)
            expect(Nokogiri::HTML(response.body).at_css('tbody#companies').text).to include(company.name)
          end
        end

        context 'when query params match partially and are case-insensitive' do
          it 'returns companies with partial match' do
            get "/accounts/#{account.id}/companies", params: { query: 'sAmPl' }
            expect(response).to have_http_status(200)
            expect(Nokogiri::HTML(response.body).at_css('tbody#companies').text).to include(company.name)
          end
        end

        context 'when query params do not match any companies' do
          it 'returns an empty companies table' do
            get "/accounts/#{account.id}/companies", params: { query: 'NonexistentCompany123' }
            expect(response).to have_http_status(200)
            table_body = Nokogiri::HTML(response.body).at_css('tbody#companies').text
            expect(table_body).not_to include(company.name)
            expect(table_body.strip.empty?).to be_truthy
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/companies/new' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/companies/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders new company page' do
        get "/accounts/#{account.id}/companies/new"
        expect(response).to have_http_status(200)
        expect(response.body).to include(I18n.t('activerecord.models.company.new'))
      end
    end
  end

  describe 'POST /accounts/{account.id}/companies' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/accounts/#{account.id}/companies", params: {} }.not_to change(Company, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        { company: { name: 'Company name', email: 'company@example.com', phone: '+5511999999999',
                     label_list: 'partner, vip' } }
      end
      before do
        sign_in(user)
      end

      it 'creates a company, replaces the drawer with its details and appends it to the companies table' do
        expect do
          post "/accounts/#{account.id}/companies", params:, as: :turbo_stream
        end.to change(Company, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(company_last.name).to eq('Company name')
        expect(company_last.email).to eq('company@example.com')
        expect(company_last.phone).to eq('+5511999999999')
        expect(company_last.label_list).to match_array(%w[partner vip])
        expect(response.body).to include('<turbo-stream action="replace" target="drawer">')
        expect(response.body).to include('<turbo-stream action="replace" target="flash_message">')
        expect(response.body).to include('<turbo-stream action="append" target="companies">')
        expect(response.body).to include(I18n.t('flash_messages.created', model: Company.model_name.human))
        expect(response.body).to include("company_#{company_last.id}")
      end

      context 'when there are multiple attachments' do
        it 'should create company and attachments' do
          params = { company: { name: 'Company name',
                                attachments_attributes: [{ file: get_file('patrick.png') },
                                                         { file: get_file('video_test.mp4') },
                                                         { file: get_file('hello_world.txt') },
                                                         { file: get_file('hello_world.rar') }] } }
          expect do
            post "/accounts/#{account.id}/companies", params:
          end.to change(Company, :count).by(1)
          expect(company_last.attachments.count).to eq(4)
          expect(company_last.image_attachments.count).to eq(1)
          expect(company_last.video_attachments.count).to eq(1)
          expect(company_last.file_attachments.count).to eq(2)
        end
      end

      context 'when company creation fails' do
        context 'when name is blank' do
          it 'should return error' do
            params = { company: { name: '', email: 'company@example.com' } }
            expect do
              post "/accounts/#{account.id}/companies", params:
            end.to change(Company, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('can&#39;t be blank')
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/companies/{company.id}' do
    let!(:company) { create(:company) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/companies/#{company.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'gets company details' do
        get "/accounts/#{account.id}/companies/#{company.id}"
        expect(response).to have_http_status(200)
        expect(response.body).to include(ERB::Util.html_escape(company.name))
        expect(response.body).to include(company.email)
        expect(response.body).to include(company.phone)
      end

      context 'when the company has contacts' do
        let!(:company_contact) { create(:company_contact, company:) }

        it 'lists the linked contacts' do
          get "/accounts/#{account.id}/companies/#{company.id}"
          expect(response).to have_http_status(200)
          expect(response.body).to include(company_contact.contact.full_name)
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/companies/{company.id}/edit' do
    let!(:company) { create(:company) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/companies/#{company.id}/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders edit company page' do
        get "/accounts/#{account.id}/companies/#{company.id}/edit"
        expect(response).to have_http_status(200)
        expect(response.body).to include(ERB::Util.html_escape(company.name))
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/companies/{company.id}' do
    let!(:company) { create(:company) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/companies/#{company.id}", params: {}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'updates the company' do
        params = { company: { name: 'Company Updated Name', label_list: 'vip' } }
        patch("/accounts/#{account.id}/companies/#{company.id}", params:)
        expect(response).to redirect_to(account_company_path(account, company))
        expect(company.reload.name).to eq('Company Updated Name')
        expect(company.label_list).to match_array(['vip'])
      end

      context 'when update fails' do
        it 'when name is blank' do
          params = { company: { name: '' } }
          patch("/accounts/#{account.id}/companies/#{company.id}", params:)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(company.reload.name).not_to eq('')
        end
      end
    end
  end

  describe 'DELETE /accounts/{account.id}/companies/{company.id}' do
    let!(:company) { create(:company) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/companies/#{company.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'deletes the company' do
        expect do
          delete "/accounts/#{account.id}/companies/#{company.id}"
        end.to change(Company, :count).by(-1)
        expect(response).to redirect_to(account_companies_path(account))
      end
    end
  end

  describe 'GET /accounts/{account.id}/companies/{company.id}/edit_custom_attributes' do
    let!(:custom_attribute_definition) { create(:custom_attribute_definition, :company_attribute) }
    let!(:contact_custom_attribute_definition) { create(:custom_attribute_definition, :contact_attribute) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/companies/#{company.id}/edit_custom_attributes"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders only the company custom attribute definitions' do
        get "/accounts/#{account.id}/companies/#{company.id}/edit_custom_attributes"
        expect(response).to have_http_status(200)
        expect(response.body).to include(custom_attribute_definition.attribute_display_name)
        expect(response.body).not_to include(contact_custom_attribute_definition.attribute_display_name)
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/companies/{company.id}/update_custom_attributes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/companies/#{company.id}/update_custom_attributes", params: {}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'updates company custom attributes' do
        params = { company: { att_value: 'Technology', att_key: 'segment' } }
        patch("/accounts/#{account.id}/companies/#{company.id}/update_custom_attributes", params:)
        expect(response).to have_http_status(204)
        expect(company.reload.custom_attributes).to match({ 'segment' => 'Technology' })
      end
    end
  end

  describe 'GET /accounts/{account.id}/companies/{company.id}/new_company_contact' do
    let!(:company) { create(:company) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/companies/#{company.id}/new_company_contact"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders the form to link a contact to the company' do
        get "/accounts/#{account.id}/companies/#{company.id}/new_company_contact"
        expect(response).to have_http_status(200)
        expect(response.body).to include('select_contact_search')
        expect(response.body).to include('company_contact[company_id]')
        expect(response.body).to include('value="company"')
      end
    end
  end

  describe 'GET /accounts/{account.id}/companies/select_company_search' do
    let!(:company) { create(:company, name: 'Sample Company') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/companies/select_company_search"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders the select company search component' do
        get "/accounts/#{account.id}/companies/select_company_search"
        expect(response).to have_http_status(200)
        html = Nokogiri::HTML(response.body)
        expect(html.at_css('turbo-frame#select_company_results').text).to include(company.name)
      end

      context 'when there is a query parameter' do
        it 'should return the matching company' do
          get "/accounts/#{account.id}/companies/select_company_search", params: { query: company.name }
          expect(response).to have_http_status(200)
          html = Nokogiri::HTML(response.body)
          expect(html.at_css('turbo-frame#select_company_results').text).to include(company.name)
        end

        context 'when query parameter is not found' do
          it 'should return 0 companies' do
            get "/accounts/#{account.id}/companies/select_company_search", params: { query: 'teste' }
            expect(response).to have_http_status(200)
            company_list_frame = Nokogiri::HTML(response.body).at_css('turbo-frame#select_company_results').text
            expect(company_list_frame).not_to include(company.name)
            expect(company_list_frame.strip.empty?).to be_truthy
          end
        end
      end

      context 'when there is a form_name parameter' do
        it 'should render form_name as hidden_field_name on html form' do
          get "/accounts/#{account.id}/companies/select_company_search",
              params: { form_name: 'company_contact[company_id]' }
          expect(response).to have_http_status(200)
          expect(response.body).to include('company_contact[company_id]')
        end
      end
    end
  end
end
