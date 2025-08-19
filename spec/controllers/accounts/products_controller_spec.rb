require 'rails_helper'

RSpec.describe Accounts::ProductsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:product) { create(:product) }
  let(:product_last) { Product.last }

  def get_file(name)
    Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/files/#{name}")
  end

  describe 'GET /accounts/{account.id}/products' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/products"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let!(:product) { create(:product) }

      before do
        sign_in(user)
      end

      it 'lists products' do
        get "/accounts/#{account.id}/products"
        expect(response).to have_http_status(200)
        expect(response.body).to include(product.name)
        expect(response.body).to include(product.identifier)
        expect(response.body).to include(product.created_at.to_s)
      end

      context 'when query params are present' do
        let!(:product) do
          create(:product, name: 'Sample Product', identifier: 'PROD-123')
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
            expect(response.body).to include(product.amount_in_cents.to_s)
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
            create(:product, name: 'Another Product', identifier: 'PROD-456')
          end
          let!(:product3) do
            create(:product, name: 'Third Product', identifier: 'PROD-789')
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
            create(:product, name: 'Sample Widget', identifier: 'PROD-456')
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

      it 'renders new product page' do
        get "/accounts/#{account.id}/products/new"
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'POST /accounts/{account.id}/products' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/accounts/#{account.id}/products", params: {} }.not_to change(Product, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        { product: { name: 'Product name', identifier: 'id123', amount_in_cents: '1500,99', quantity_available: '10',
                     description: 'Product description', account_id: account.id } }
      end
      before do
        sign_in(user)
      end

      it 'creates a product' do
        expect do
          post "/accounts/#{account.id}/products", params:
        end.to change(Product, :count).by(1)
        expect(response).to redirect_to(account_products_path(account))
        expect(product_last.name).to eq('Product name')
        expect(product_last.identifier).to eq('id123')
        expect(product_last.amount_in_cents).to eq(150_099)
        expect(product_last.quantity_available).to eq(10)
        expect(product_last.description).to eq('Product description')
        expect(product_last.account_id).to eq(account.id)
      end

      context 'when there are multiple attachments' do
        it 'should create product and attachemnts' do
          params = { product: { name: 'Product name', identifier: 'id123', amount_in_cents: '1500,99', quantity_available: '10',
                                description: 'Product description', attachments_attributes: [{ file: get_file('patrick.png') }, { file: get_file('video_test.mp4') }, { file: get_file('hello_world.txt') }, { file: get_file('hello_world.rar') }] } }
          expect do
            post "/accounts/#{account.id}/products",
                  params:
          end.to change(Product, :count).by(1)
          expect(response).to redirect_to(account_products_path(account))
          expect(product_last.name).to eq('Product name')
          expect(product_last.attachments.count).to eq(4)
          expect(product_last.image_attachments.count).to eq(1)
          expect(product_last.video_attachments.count).to eq(1)
          expect(product_last.file_attachments.count).to eq(2)
        end
      end

      context 'when product creation fails' do
        context 'when quantity_available is invalid' do
          it 'when quantity_available is negative' do
            params = { product: { name: 'Product name', identifier: 'id123', amount_in_cents: '150099', quantity_available: '-10',
                                  description: 'Product description', account_id: account.id } }
            expect do
              post "/accounts/#{account.id}/products",
                    params:
            end.to change(Product, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Can not be negative')
          end
        end

        context 'when amount_in_cents is invalid' do
          it 'when amount_in_cents is negative' do
            params = { product: { name: 'Product name', identifier: 'id123', amount_in_cents: '-150099', quantity_available: '10',
                                  description: 'Product description', account_id: account.id } }
            expect do
              post "/accounts/#{account.id}/products",
                    params:
            end.to change(Product, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Can not be negative')
          end
        end

        context 'when there is an invalid file_type attachement' do
          before do
            allow_any_instance_of(Attachment).to receive(:check_file_type).and_return(nil)
          end
          it 'should return error' do
            params = { product: { name: 'Product name', identifier: 'id123', amount_in_cents: '1500,99', quantity_available: '10',
                                  description: 'Product description', attachments_attributes: [{ file: get_file('patrick.png') }, { file: get_file('hello_world.txt') }] } }
            expect do
              post "/accounts/#{account.id}/products",
                    params:
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
            params = { product: { name: 'Product name', identifier: 'id123', amount_in_cents: '1500,99', quantity_available: '10',
                                  description: 'Product description', attachments_attributes: [{ file: get_file('patrick.png') }] } }
            expect do
              post "/accounts/#{account.id}/products",
                    params:
            end.to change(Product, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Attachments file size is too big')
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/products/{product.id}' do
    let!(:product) { create(:product) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/products/#{product.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'gets product by account' do
        get "/accounts/#{account.id}/products/#{product.id}"
        expect(response).to have_http_status(200)
        expect(response.body).to include(product.name)
        expect(response.body).to include(product.identifier)
      end
    end
  end

  describe 'GET /accounts/{account.id}/products/{product.id}/edit' do
    let!(:product) { create(:product) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/products/#{product.id}/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'renders edit product page' do
        get "/accounts/#{account.id}/products/#{product.id}/edit"
        expect(response).to have_http_status(200)
        expect(response.body).to include(product.name)
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/products/{product.id}' do
    let!(:product) { create(:product) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/products/#{product.id}", params: {}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        { product: { name: 'Product Updated Name', amount_in_cents: '63.580,36' } }
      end
      before do
        sign_in(user)
      end

      it 'updates the product' do
        patch("/accounts/#{account.id}/products/#{product.id}", params:)
        expect(response).to redirect_to(edit_account_product_path(account, product))
        expect(product.reload.name).to eq('Product Updated Name')
        expect(product.amount_in_cents).to eq(6_358_036)
      end

      context 'when update fails' do
        context 'when quantity_available is invalid' do
          it 'when quantity_available is negative' do
            params = { product: { quantity_available: '-30' } }
            patch("/accounts/#{account.id}/products/#{product.id}", params:)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Can not be negative')
          end
        end

        context 'when amount_in_cents is invalid' do
          it 'when amount_in_cents is negative' do
            params = { product: { amount_in_cents: '-150000' } }
            patch("/accounts/#{account.id}/products/#{product.id}", params:)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Can not be negative')
          end
        end
      end
    end
  end

  describe 'DELETE /accounts/{account.id}/products/{product.id}' do
    let!(:product) { create(:product) }

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

      it 'deletes the product' do
        expect do
          delete "/accounts/#{account.id}/products/#{product.id}"
        end.to change(Product, :count).by(-1)
        expect(response).to redirect_to(account_products_path(account))
      end

      context 'when there is product deal_product relationship' do
        let!(:deal_product) { create(:deal_product, product:, account:) }
        it 'should delete product and deal_product' do
          expect do
            delete "/accounts/#{account.id}/products/#{product.id}"
          end.to change(Product, :count).by(-1)
                                        .and change(DealProduct, :count).by(-1)
          expect(response.body).to redirect_to(account_products_path(account.id))
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

      it 'renders edit custom attributes page' do
        get "/accounts/#{account.id}/products/#{product.id}/edit_custom_attributes"
        expect(response).to have_http_status(200)
        expect(response.body).to include(custom_attribute_definition.attribute_display_name)
        expect(response.body).not_to include(contact_custom_attribute_definition.attribute_display_name)
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/products/{product.id}/update_custom_attributes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/products/#{product.id}/update_custom_attributes", params: {}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) { { product: { att_value: 'SKU display name', att_key: 'SKU' } } }

      before do
        sign_in(user)
      end

      it 'updates product custom attributes' do
        patch("/accounts/#{account.id}/products/#{product.id}/update_custom_attributes",
              params:)
        expect(response).to have_http_status(204)
        expect(product.reload.custom_attributes).to match({ 'SKU' => 'SKU display name' })
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

          context 'when query parameter is not found' do
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
