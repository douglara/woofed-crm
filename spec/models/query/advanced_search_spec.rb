# spec/services/query/advanced_search_spec.rb

require 'rails_helper'

RSpec.describe Query::AdvancedSearch, type: :service do
  let!(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:q) { nil }
  let(:search_type) { nil }
  let(:params) { { q:, search_type: } }

  subject { described_class.new(user, account, params) }

  describe '#initialize' do
    it 'raises ArgumentError if current_user is nil' do
      expect { described_class.new(nil, account, params) }
        .to raise_error(ArgumentError, /current_user is required/)
    end

    it 'raises ArgumentError if current_account is nil' do
      expect { described_class.new(user, nil, params) }
        .to raise_error(ArgumentError, /current_account is required/)
    end

    it 'raises ArgumentError if params is nil' do
      expect { described_class.new(user, account, nil) }
        .to raise_error(ArgumentError, /params is required/)
    end

    it 'sets instance variables correctly' do
      instance = described_class.new(user, account, params)

      expect(instance.instance_variable_get(:@current_user)).to eq(user)
      expect(instance.instance_variable_get(:@current_account)).to eq(account)
      expect(instance.instance_variable_get(:@params)).to eq({ q:, search_type: })
    end
  end

  describe '#call' do
    context 'when search_type is "contact"' do
      let(:search_type) { 'contact' }
      let(:q) { 'João' }

      let!(:matching_contact) { create(:contact, full_name: 'João Silva') }
      let!(:non_matching_contact) { create(:contact, full_name: 'Maria Oliveira') }

      it 'returns only contacts and filters by query' do
        result = subject.call

        expect(result.keys).to contain_exactly(:contacts)
        expect(result[:contacts]).to include(matching_contact)
        expect(result[:contacts]).not_to include(non_matching_contact)
        expect(result[:contacts].size).to be <= 7
      end
    end

    context 'when search_type is "deal"' do
      let(:search_type) { 'deal' }
      let(:q) { 'Enterprise' }

      let!(:matching_deal)   { create(:deal, name: 'Enterprise Contract') }
      let!(:other_deal)      { create(:deal, name: 'Basic Plan') }

      it 'returns only deals matching the name' do
        result = subject.call

        expect(result.keys).to contain_exactly(:deals)
        expect(result[:deals]).to include(matching_deal)
        expect(result[:deals]).not_to include(other_deal)
      end
    end

    context 'when no search_type is provided (global search)' do
      let(:q) { 'xyz' }

      let!(:test_contacts)   { create_list(:contact, 4, full_name: 'Xyz User') }
      let!(:test_deals)      { create_list(:deal, 3, name: 'Xyz Deal') }
      let!(:test_products)   { create_list(:product, 2, name: 'Xyz Product') }
      let!(:test_pipeline)   { create(:pipeline, name: 'Xyz Pipeline') }
      let!(:test_activities) { create_list(:event, 6, kind: 'activity', title: 'Xyz Activity') }

      it 'returns up to 7 results from each type that matches the query' do
        result = subject.call

        expect(result[:contacts].size).to eq(4)
        expect(result[:deals].size).to eq(3)
        expect(result[:products].size).to eq(2)
        expect(result[:pipelines].size).to eq(1)
        expect(result[:activities].size).to eq(6)

        expect(result.keys).to contain_exactly(:contacts, :deals, :products, :pipelines, :activities)
      end
    end

    context 'when query is blank' do
      let(:search_type) { 'contact' }
      let(:q) { '' }

      let!(:old_contact)     { create(:contact, account:, updated_at: 15.days.ago) }
      let!(:recent_contacts) { create_list(:contact, 10, account:) }

      it 'returns the 7 most recently updated contacts' do
        result = subject.call[:contacts]

        expect(result.size).to eq(7)
        expect(result.first).to eq(recent_contacts.last)
        expect(result).not_to include(old_contact)
      end
    end
  end

  describe '#filter_contacts' do
    context 'with search query' do
      let!(:by_name)  { create(:contact, full_name: 'Ana Carolina') }
      let!(:by_email) { create(:contact, email: 'ana@example.com') }
      let!(:by_phone) { create(:contact, phone: '+5511999887766') }

      context 'finds contacts by full_name and email (case insensitive)' do
        let(:q) { 'ana' }

        it do
          results = subject.send(:filter_contacts)

          expect(results).to include(by_name, by_email)
          expect(results).not_to include(by_phone)
        end
      end

      context 'finds contacts by phone' do
        let(:q) { '9887766' }

        it do
          results = subject.send(:filter_contacts)

          expect(results).to include(by_phone)
          expect(results).not_to include(by_name, by_email)
        end
      end
    end

    context 'without query' do
      let(:q) { '' }

      it 'returns 7 most recent contacts ordered by updated_at DESC' do
        oldest = create(:contact, updated_at: 5.days.ago)
        newest = create(:contact, updated_at: Time.current)
        create_list(:contact, 8, updated_at: 2.days.ago)

        results = subject.send(:filter_contacts)

        expect(results.size).to eq(7)
        expect(results.first).to eq(newest)
        expect(results).not_to include(oldest)
      end
    end
  end

  describe '#filter_deals' do
    context 'with search query' do
      let(:q) { 'premium' }

      let!(:matching) { create(:deal, name: 'Premium plan') }
      let!(:other)    { create(:deal, name: 'Basic plan') }

      it 'searches only by name' do
        results = subject.send(:filter_deals)

        expect(results).to include(matching)
        expect(results).not_to include(other)
      end
    end

    context 'without query' do
      let(:q) { '' }

      it 'returns 7 most recent deals ordered by updated_at DESC' do
        oldest = create(:deal, updated_at: 5.days.ago)
        newest = create(:deal, updated_at: Time.current)
        create_list(:deal, 8, updated_at: 2.days.ago)

        results = subject.send(:filter_deals)

        expect(results.size).to eq(7)
        expect(results.first).to eq(newest)
        expect(results).not_to include(oldest)
      end
    end
  end

  describe '#filter_products' do
    context 'with search query' do
      context 'search by name' do
        let(:q) { 'PRODuct' }

        let!(:by_name)       { create(:product, account:, name: 'Pro product') }
        let!(:by_identifier) { create(:product, account:, identifier: 'PROD-2025') }

        it do
          results = subject.send(:filter_products)
          expect(results).to include(by_name)
          expect(results).not_to include(by_identifier)
        end
      end

      context 'search by identifier' do
        let(:q) { 'ID-598' }

        let!(:by_name)       { create(:product, account:, name: 'Pro product') }
        let!(:by_identifier) { create(:product, account:, identifier: 'ID-59826') }

        it do
          results = subject.send(:filter_products)
          expect(results).to include(by_identifier)
          expect(results).not_to include(by_name)
        end
      end
    end

    context 'without query' do
      let(:q) { '' }

      it 'returns 7 most recent products ordered by updated_at DESC' do
        oldest = create(:product, account:, updated_at: 5.days.ago)
        newest = create(:product, account:, updated_at: Time.current)
        create_list(:product, 8, account:, updated_at: 2.days.ago)

        results = subject.send(:filter_products)

        expect(results.size).to eq(7)
        expect(results.first).to eq(newest)
        expect(results).not_to include(oldest)
      end
    end
  end

  describe '#filter_pipelines' do
    context 'with search query' do
      let(:q) { 'Sell' }

      let!(:matching) { create(:pipeline, account:, name: 'Pipeline sell') }
      let!(:other)    { create(:pipeline, account:, name: 'Suporte') }

      it 'searches by name' do
        results = subject.send(:filter_pipelines)

        expect(results).to include(matching)
        expect(results).not_to include(other)
      end
    end

     context 'without query' do
      let(:q) { '' }

      it 'returns 7 most recent pipelines ordered by updated_at DESC' do
        oldest = create(:pipeline, account:, updated_at: 5.days.ago)
        newest = create(:pipeline, account:, updated_at: Time.current)
        create_list(:pipeline, 8, account:, updated_at: 2.days.ago)

        results = subject.send(:filter_pipelines)

        expect(results.size).to eq(7)
        expect(results.first).to eq(newest)
        expect(results).not_to include(oldest)
      end
    end
  end

  describe '#filter_activities' do
    context 'with search query' do
      let(:q) { 'Call' }

      let!(:matching) { create(:event, title: 'call with client', kind: 'activity') }
      let!(:other)    { create(:event, title: 'internal task', kind: 'activity') }
      let!(:other2) { create(:event, title: 'call task', kind: 'note') }

      it 'searches by title' do
        results = subject.send(:filter_activities)

        expect(results).to include(matching)
        expect(results).not_to include(other)
        expect(results).not_to include(other2)
      end
    end

    skip 'without query' do
      let(:q) { '' }

      it 'returns 7 most recent activities ordered by updated_at DESC' do
        travel_to(Time.current) do
          oldest = create(:event, kind: 'activity', updated_at: 5.days.ago)
          newest = create(:event, kind: 'activity', updated_at: Time.current)
          create_list(:event, 8, kind: 'activity', updated_at: 2.days.ago)

          results = subject.send(:filter_activities)

          expect(results.size).to eq(7)
          expect(results.first).to eq(newest)
          expect(results).not_to include(oldest)
        end
      end
    end
  end

  describe '#search_query' do
    let(:q) { '    Test    ' }
    it 'strips the query' do
      expect(subject.send(:search_query)).to eq('Test')
    end
  end

  describe '#search_type' do
    let(:search_type) { 'DeAl' }

    it 'downcases search_type' do
      expect(subject.send(:search_type)).to eq('deal')
    end
  end
end
