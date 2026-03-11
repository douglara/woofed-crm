require 'rails_helper'

RSpec.describe Inertia::Accounts::Components::ComboboxController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }

  let(:base_url) { "/inertia/accounts/#{account.id}/components/combobox" }

  describe 'GET /inertia/accounts/{account.id}/components/combobox' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get base_url, params: { model: 'user' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }

      context 'when searching users' do
        let!(:user_a) { create(:user, full_name: 'Alice Santos') }
        let!(:user_b) { create(:user, full_name: 'Bob Costa') }

        it 'returns matching users' do
          get base_url, params: { model: 'user', q: { full_name_or_email_cont: 'Alice' } }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          labels = json.map { |r| r['label'] }
          expect(labels).to include('Alice Santos')
          expect(labels).not_to include('Bob Costa')
        end

        it 'returns all users when no query filter is given' do
          get base_url, params: { model: 'user' }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json.length).to be >= 2
        end

        it 'returns value and label keys' do
          get base_url, params: { model: 'user' }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json.first).to have_key('value')
          expect(json.first).to have_key('label')
        end
      end

      context 'when searching contacts' do
        let!(:contact_a) do
          create(:contact, full_name: 'Carlos Almeida', email: 'carlos@test.com', phone: '+5511999990001')
        end
        let!(:contact_b) do
          create(:contact, full_name: 'Diana Souza', email: 'diana@test.com', phone: '+5511999990002')
        end

        it 'returns matching contacts' do
          get base_url, params: { model: 'contact', q: { full_name_or_email_cont: 'Carlos' } }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          labels = json.map { |r| r['label'] }
          expect(labels).to include('Carlos Almeida')
          expect(labels).not_to include('Diana Souza')
        end
      end

      context 'when searching products' do
        let!(:product_a) { create(:product, name: 'Premium Plan') }
        let!(:product_b) { create(:product, name: 'Basic Plan') }

        it 'returns matching products' do
          get base_url, params: { model: 'product', q: { name_cont: 'Premium' } }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          labels = json.map { |r| r['label'] }
          expect(labels).to include('Premium Plan')
          expect(labels).not_to include('Basic Plan')
        end
      end

      context 'when searching pipelines' do
        let!(:pipeline_a) { create(:pipeline, name: 'Sales Pipeline') }
        let!(:pipeline_b) { create(:pipeline, name: 'Support Pipeline') }

        it 'returns matching pipelines' do
          get base_url, params: { model: 'pipeline', q: { name_cont: 'Sales' } }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          labels = json.map { |r| r['label'] }
          expect(labels).to include('Sales Pipeline')
          expect(labels).not_to include('Support Pipeline')
        end
      end

      context 'when searching stages' do
        let!(:pipeline) { create(:pipeline) }
        let!(:stage_a) { create(:stage, name: 'Negotiation', pipeline:) }
        let!(:stage_b) { create(:stage, name: 'Proposal', pipeline:) }

        it 'returns matching stages' do
          get base_url, params: { model: 'stage', q: { name_cont: 'Negotiation' } }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          labels = json.map { |r| r['label'] }
          expect(labels).to include('Negotiation')
          expect(labels).not_to include('Proposal')
        end
      end

      context 'when searching deals' do
        let!(:deal_a) { create(:deal, name: 'Enterprise Deal') }
        let!(:deal_b) { create(:deal, name: 'Startup Deal') }

        it 'returns matching deals' do
          get base_url, params: { model: 'deal', q: { name_cont: 'Enterprise' } }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          labels = json.map { |r| r['label'] }
          expect(labels).to include('Enterprise Deal')
          expect(labels).not_to include('Startup Deal')
        end
      end

      context 'when model param is invalid' do
        it 'returns 422 with error message' do
          get base_url, params: { model: 'nonexistent' }
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('Invalid parameters')
        end
      end

      context 'when searching labels (tags)' do
        let!(:contact) do
          create(:contact, full_name: 'Tag Test Contact', email: 'tagtest@test.com', phone: '+5511999990099')
        end

        before do
          contact.label_list.add('VIP', 'Premium')
          contact.save!
        end

        it 'returns tags instead of model records' do
          get base_url, params: { model: 'labels', q: { name_cont: 'VIP' } }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          labels = json.map { |r| r['label'] }
          expect(labels).to include('VIP')
          expect(labels).not_to include('Premium')
        end
      end
    end
  end
end
