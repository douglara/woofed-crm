require 'rails_helper'
require 'action_controller'

RSpec.describe DealProductBuilder do
  let!(:account) { create(:account) }
  let!(:product) do
    create(:product, account:, amount_in_cents: 1000, identifier: 'prod_123', name: 'Test Product')
  end
  let!(:deal) { create(:deal, account:) }

  describe 'when building a DealProduct' do
    context 'with valid params (as processed by controller)' do
      let(:params) do
        ActionController::Parameters.new(
          quantity: 2,
          product_id: product.id,
          deal_id: deal.id
        )
      end

      it 'builds and returns a DealProduct with correct attributes' do
        deal_product = described_class.new(params).perform
        expect(deal_product.quantity).to eq(2)
        expect(deal_product.product_id).to eq(product.id)
        expect(deal_product.deal_id).to eq(deal.id)
        expect(deal_product.unit_amount_in_cents).to eq(1000)
        expect(deal_product.product_identifier).to eq('prod_123')
        expect(deal_product.product_name).to eq('Test Product')
        expect(deal_product.id).to be_nil
      end
    end

    context 'when params are empty' do
      let(:params) do
        ActionController::Parameters.new({})
      end

      it 'builds and returns a DealProduct with default attributes' do
        deal_product = described_class.new(params).perform
        expect(deal_product.quantity).to eq(1)
        expect(deal_product.product_id).to be_nil
        expect(deal_product.deal_id).to be_nil
        expect(deal_product.unit_amount_in_cents).to be_nil
        expect(deal_product.product_identifier).to be_nil
        expect(deal_product.product_name).to be_nil
        expect(deal_product.id).to be_nil
      end
    end

    context 'when params contain invalid product_id' do
      let(:params) do
        ActionController::Parameters.new(
          quantity: 2,
          product_id: 999,
          deal_id: deal.id
        )
      end

      it 'builds and returns a DealProduct with nil product-related attributes' do
        deal_product = described_class.new(params).perform
        expect(deal_product.quantity).to eq(2)
        expect(deal_product.product_id).to eq(999)
        expect(deal_product.deal_id).to eq(deal.id)
        expect(deal_product.unit_amount_in_cents).to be_nil
        expect(deal_product.product_identifier).to be_nil
        expect(deal_product.product_name).to be_nil
        expect(deal_product.id).to be_nil
      end
    end
  end
end
