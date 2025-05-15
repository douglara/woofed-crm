require 'rails_helper'

RSpec.describe Accounts::UsersController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:product) { create(:product) }
  let!(:contact) { create(:contact) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage) { create(:stage, pipeline:) }
  let!(:deal) { create(:deal, stage:, contact:) }
  let(:deal_product) { create(:deal_product, deal:, product:) }
  let(:product_first) { Product.first }
  def get_file(name)
    Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/files/#{name}")
  end

  describe 'POST /accounts/{account.id}/products' do
    let(:valid_params) do
      { product: { name: 'Product name', identifier: 'id123', amount_in_cents: '1500,99', quantity_available: '10',
                   description: 'Product description' } }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/products"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'create product' do
        it do
          expect do
            post "/accounts/#{account.id}/products",
                 params: valid_params
          end.to change(Product, :count).by(1)
          expect(response).to redirect_to(account_products_path(account))
          expect(product_first.name).to eq('Product name')
          expect(product_first.identifier).to eq('id123')
          expect(product_first.amount_in_cents).to eq(150_099)
          expect(product_first.quantity_available).to eq(10)
          expect(product_first.description).to eq('Product description')
        end

        context 'when quantity_available is invalid' do
          it 'when quantity_available is negative' do
            invalid_params = { product: { name: 'Product name', identifier: 'id123', amount_in_cents: '150099', quantity_available: '-10',
                                          description: 'Product description' } }
            expect do
              post "/accounts/#{account.id}/products",
                   params: invalid_params
            end.to change(Product, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Can not be negative')
          end
        end

        context 'when amount_in_cents is invalid' do
          it 'when amount_in_cents is negative' do
            invalid_params = { product: { name: 'Product name', identifier: 'id123', amount_in_cents: '-150099', quantity_available: '10',
                                          description: 'Product description' } }
            expect do
              post "/accounts/#{account.id}/products",
                   params: invalid_params
            end.to change(Product, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Can not be negative')
          end
        end
        context 'when there are multiple attachments' do
          it 'should create product and attachemnts' do
            valid_params = { product: { name: 'Product name', identifier: 'id123', amount_in_cents: '1500,99', quantity_available: '10',
                                        description: 'Product description', attachments_attributes: [{ file: get_file('patrick.png') }, { file: get_file('video_test.mp4') }, { file: get_file('hello_world.txt') }, { file: get_file('hello_world.rar') }] } }
            expect do
              post "/accounts/#{account.id}/products",
                   params: valid_params
            end.to change(Product, :count).by(1)
            expect(response).to redirect_to(account_products_path(account))
            expect(product_first.name).to eq('Product name')
            expect(product_first.attachments.count).to eq(4)
            expect(product_first.image_attachments.count).to eq(1)
            expect(product_first.video_attachments.count).to eq(1)
            expect(product_first.file_attachments.count).to eq(2)
          end
        end
        context 'when there is an invalid file_type attachement' do
          before do
            allow_any_instance_of(Attachment).to receive(:check_file_type).and_return(nil)
          end
          it 'should return error' do
            valid_params = { product: { name: 'Product name', identifier: 'id123', amount_in_cents: '1500,99', quantity_available: '10',
                                        description: 'Product description', attachments_attributes: [{ file: get_file('patrick.png') }, { file: get_file('hello_world.txt') }] } }
            expect do
              post "/accounts/#{account.id}/products",
                   params: valid_params
            end.to change(Product, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Attachments file type not supported')
          end
        end
        context 'when there is an invalid attachement (size is too big)' do
          before do
            allow_any_instance_of(Attachment).to receive(:acceptable_file_size).and_return(true)
          end

          it 'should return error' do
            valid_params = { product: { name: 'Product name', identifier: 'id123', amount_in_cents: '1500,99', quantity_available: '10',
                                        description: 'Product description', attachments_attributes: [{ file: get_file('patrick.png') }] } }
            expect do
              post "/accounts/#{account.id}/products",
                   params: valid_params
            end.to change(Product, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Attachments file size is too big')
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/products' do
    let!(:product) { create(:product) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/products"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'get products' do
        it 'get products by account' do
          get "/accounts/#{account.id}/products"
          expect(response).to have_http_status(200)
          expect(response.body).to include(product.name)
          expect(response.body).to include(product.identifier)
          expect(response.body).to include(I18n.l(product.created_at, format: :long))
        end
      end
      context 'when query params are present' do
        let!(:product) do
          create(:product, account:, name: 'Sample Product', identifier: 'PROD-123')
        end
        context 'when query params match with product name' do
          it 'returns products on products table' do
            get "/accounts/#{account.id}/products", params: { query: product.name }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Products')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#products').text
            expect(table_body).to include(ERB::Util.html_escape(product.name))
            expect(table_body).to include(product.identifier)
            expect(table_body).to include(product.amount_in_cents_at_format)
            expect(table_body).to include(product.quantity_available.to_s)
          end
        end

        context 'when query params match with product identifier' do
          it 'returns products on products table' do
            get "/accounts/#{account.id}/products", params: { query: product.identifier }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Products')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#products').text
            expect(table_body).to include(ERB::Util.html_escape(product.name))
            expect(table_body).to include(product.identifier)
          end
        end

        context 'when query params match partially with product name' do
          let(:partial_name) { product.name.split.first }
          it 'returns products with partial match' do
            get "/accounts/#{account.id}/products", params: { query: partial_name }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Products')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#products').text
            expect(table_body).to include(ERB::Util.html_escape(product.name))
            expect(table_body).to include(product.identifier)
          end
        end

        context 'when query params match partially with product identifier' do
          let(:partial_identifier) { product.identifier.split('-').first }
          it 'returns products with partial match' do
            get "/accounts/#{account.id}/products", params: { query: partial_identifier }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Products')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#products').text
            expect(table_body).to include(ERB::Util.html_escape(product.name))
            expect(table_body).to include(product.identifier)
          end
        end

        context 'when query params are case-insensitive' do
          it 'returns products regardless of case' do
            get "/accounts/#{account.id}/products", params: { query: product.name.swapcase }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Products')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#products').text
            expect(table_body).to include(ERB::Util.html_escape(product.name))
            expect(table_body).to include(product.identifier)
          end
        end

        context 'when query params do not match any products' do
          it 'returns an empty products table' do
            get "/accounts/#{account.id}/products", params: { query: 'NonexistentProduct123' }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Products')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#products').text
            expect(table_body).not_to include(ERB::Util.html_escape(product.name))
            expect(table_body).not_to include(product.identifier)
            expect(table_body).not_to include(product.id.to_s)
          end
        end

        context 'when there are multiple products and query does not match any' do
          let!(:product2) do
            create(:product, account:, name: 'Another Product', identifier: 'PROD-456')
          end
          let!(:product3) do
            create(:product, account:, name: 'Third Product', identifier: 'PROD-789')
          end

          it 'returns an empty products table' do
            get "/accounts/#{account.id}/products", params: { query: 'NonexistentProduct123' }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Products')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#products').text
            expect(table_body).not_to include(ERB::Util.html_escape(product.name))
            expect(table_body).not_to include(ERB::Util.html_escape(product2.name))
            expect(table_body).not_to include(ERB::Util.html_escape(product3.name))
          end
        end

        context 'when query params match multiple products' do
          let!(:product2) do
            create(:product, account:, name: 'Sample Widget', identifier: 'PROD-456')
          end
          let(:common_query) { 'Sample' }

          it 'returns all matching products' do
            get "/accounts/#{account.id}/products", params: { query: common_query }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Products')
            doc = Nokogiri::HTML(response.body)
            table_body = doc.at_css('tbody#products').text
            expect(table_body).to include(ERB::Util.html_escape(product.name))
            expect(table_body).to include(ERB::Util.html_escape(product2.name))
            expect(table_body).to include(product.identifier)
            expect(table_body).to include(product2.identifier)
          end
        end
      end
    end
  end
  describe 'PACTH /accounts/{account.id}/products/{product.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/products/#{product.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'update product' do
        let(:valid_params) do
          { product: { name: 'Product Updated Name', amount_in_cents: '63.580,36' } }
        end
        it do
          patch "/accounts/#{account.id}/products/#{product.id}", params: valid_params
          expect(response.body).to redirect_to(edit_account_product_path(account, product_first))
          expect(product_first.name).to eq('Product Updated Name')
          expect(product_first.amount_in_cents).to eq(6_358_036)
        end
        context 'when quantity_available is invalid' do
          it 'when quantity_available is negative' do
            invalid_params = { product: { quantity_available: '-30' } }
            patch "/accounts/#{account.id}/products/#{product.id}", params: invalid_params
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Can not be negative')
          end
        end

        context 'when amount_in_cents is invalid' do
          it 'when amount_in_cents is negative' do
            invalid_params = { product: { amount_in_cents: '-150000' } }
            patch "/accounts/#{account.id}/products/#{product.id}", params: invalid_params
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Can not be negative')
          end
        end
      end
    end
  end
  describe 'DELETE /accounts/{account.id}/products/{product.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/products/#{product.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'delete the product' do
        it do
          delete "/accounts/#{account.id}/products/#{product.id}"
          expect(response.body).to redirect_to(account_products_path(account))
          expect(Product.count).to eq(0)
        end
      end
      context 'when there is product deal_product relationship' do
        let!(:deal_product) { create(:deal_product, deal:, product:) }
        it 'should delete product and deal_product' do
          delete "/accounts/#{account.id}/products/#{product.id}"
          expect(response.body).to redirect_to(account_products_path(account))
          expect(Product.count).to eq(0)
          expect(DealProduct.count).to eq(0)
        end
      end
    end
  end
  describe 'GET /accounts/{account.id}/products/new' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/products/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'new product page' do
        it do
          get "/accounts/#{account.id}/products/new"
          expect(response).to have_http_status(200)
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/products/{product.id}/edit_custom_attributes' do
    let!(:custom_attribute_definition) { create(:custom_attribute_definition, :product_attribute) }
    let!(:contact_custom_attribute_definition) do
      create(:custom_attribute_definition, :contact_attribute)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/products/#{product.id}/edit_custom_attributes"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'edit product custom attributes page' do
        it do
          get "/accounts/#{account.id}/products/#{product.id}/edit_custom_attributes"
          expect(response).to have_http_status(200)
          expect(response.body).to include(custom_attribute_definition.attribute_display_name)
          expect(response.body).not_to include(contact_custom_attribute_definition.attribute_display_name)
        end
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/products/{product.id}/update_custom_attributes' do
    let(:valid_params) do
      { product: { att_value: 'CPF display name', att_key: 'CPF' } }
    end
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/products/#{product.id}/update_custom_attributes"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'update product custom attributes' do
        it do
          patch "/accounts/#{account.id}/products/#{product.id}/update_custom_attributes", params: valid_params
          expect(response).to have_http_status(204)
          expect(product.reload.custom_attributes).to match({ 'CPF' => 'CPF display name' })
        end
      end
    end
  end
  describe 'GET /accounts/{account.id}/products/select_product_search?query=query' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/products/select_product_search", params: { query: 'query' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'select product search component' do
        it do
          get "/accounts/#{account.id}/products/select_product_search"
          expect(response).to have_http_status(200)
        end

        context 'when there is query parameter' do
          it 'should return product' do
            get "/accounts/#{account.id}/products/select_product_search", params: { query: product.name }
            expect(response).to have_http_status(200)

            html = Nokogiri::HTML(response.body)
            product_list_frame = html.at_css('turbo-frame#select_product_results').text
            expect(product_list_frame).to include(product.name)
          end

          context 'when query paramenter is not found' do
            it 'should return 0 products' do
              get "/accounts/#{account.id}/products/select_product_search", params: { query: 'teste' }
              expect(response).to have_http_status(200)

              html = Nokogiri::HTML(response.body)
              product_list_frame = html.at_css('turbo-frame#select_product_results').text
              expect(product_list_frame).not_to include(product.name)
              expect(product_list_frame.strip.empty?).to be_truthy
            end
          end
        end

        context 'when there is a form_name parameter' do
          it 'should render form_name as hidden_field_name on html form' do
            get "/accounts/#{account.id}/products/select_product_search",
                params: { form_name: 'deal_product[product_id]' }

            expect(response).to have_http_status(200)
            expect(response.body).not_to include('click->select-search#select')
            expect(response.body).to include('deal_product[product_id]')
          end
        end

        context 'when there is no form_name parameter' do
          it 'should not render a specific hidden_field_name on html form' do
            get "/accounts/#{account.id}/products/select_product_search"

            expect(response).to have_http_status(200)
            expect(response.body).not_to include('click->select-search#select')
            expect(response.body).not_to include('deal_product[product_id]')
          end
        end

        context 'when there is a content_value parameter' do
          it 'should render content_value as selected_model_name on html form' do
            get "/accounts/#{account.id}/products/select_product_search",
                params: { content_value: 'product_name_test' }

            expect(response).to have_http_status(200)
            expect(response.body).to include('product_name_test')
            expect(response.body).not_to include('Search product')
          end
        end

        context 'when there is no content_value parameter' do
          it 'should render the default search placeholder instead of a selected name' do
            get "/accounts/#{account.id}/products/select_product_search"

            expect(response).to have_http_status(200)
            expect(response.body).not_to include('product_name_test')
            expect(response.body).to include('Search product')
          end
        end

        context 'when there is a form_id parameter' do
          it 'should render form_id as hidden_field_value on html form' do
            get "/accounts/#{account.id}/products/select_product_search",
                params: { form_id: '789' }

            expect(response).to have_http_status(200)
            expect(response.body).to include('value="789"')
          end
        end

        context 'when there is no form_id parameter' do
          it 'should not render a specific id in the hidden field' do
            get "/accounts/#{account.id}/products/select_product_search"

            expect(response).to have_http_status(200)
            expect(response.body).not_to include('value="789"')
          end
        end

        context 'when all parameters are present' do
          it 'should render all parameters correctly in the HTML form' do
            get "/accounts/#{account.id}/products/select_product_search",
                params: {
                  form_name: 'deal_product[product_id]',
                  content_value: 'product_name_test',
                  form_id: '789'
                }

            expect(response).to have_http_status(200)
            expect(response.body).to include('deal_product[product_id]')
            expect(response.body).to include('product_name_test')
            expect(response.body).to include('value="789"')
            expect(response.body).not_to include('Search product')
          end
        end
      end
    end
  end
end
