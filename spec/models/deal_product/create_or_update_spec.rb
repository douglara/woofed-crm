require 'rails_helper'

RSpec.describe DealProduct::CreateOrUpdate do
  let!(:account) { create(:account) }
  let(:deal) { create(:deal) }
  let(:product) { create(:product) }
  let(:deal_product) { build(:deal_product, deal:, product:, product_name: 'Old Product name') }
  let(:params) { { quantity: 20, unit_amount_in_cents: 200 } }
  let(:subject) { described_class.new(deal_product, params) }

  describe '#call' do
    context 'when deal_product is invalid' do
      before do
        allow(deal_product).to receive(:invalid?).and_return(true)
      end

      it 'returns false and does not save' do
        expect(subject.call).to eq(false)
        expect(deal_product).not_to receive(:save!)
      end
    end

    context 'when deal_product is valid but does not need recalculation' do
      let(:params) { { product_name: 'Product name test' } }
      let!(:deal_product) { create(:deal_product, deal:, product_name: 'Old Product name') }

      it 'saves the deal_product and returns it' do
        expect do
          subject.call
        end.to change { deal_product.reload.product_name }.from('Old Product name').to('Product name test')
      end
    end

    context 'when deal_product needs recalculation from base values' do
      it 'recalculates values and saves within a transaction' do
        expect(deal_product).to receive(:save!).and_call_original
        expect(Deal::RecalculateAndSaveAllMonetaryValues).to receive(:new).with(deal).and_call_original

        result = subject.call
        expect(result).to eq(deal_product)
        expect(deal_product.total_amount_in_cents).to eq(20 * 200) # 4000
      end
    end

    context 'when deal_product is new' do
      let(:deal_product) { DealProduct.new(deal:, product:) }

      it 'triggers recalculation from base values' do
        expect(deal_product).to receive(:save!).and_call_original
        expect(subject.call).to eq(deal_product)
        expect(deal_product.total_amount_in_cents).to eq(20 * 200)
      end
    end
  end
end
