require 'rails_helper'

RSpec.describe Deal::RecalculateAndSaveAllMonetaryValues do
  let!(:account) { create(:account) }
  let(:deal) { create(:deal) }
  let(:product1) { create(:product, account:) }
  let(:product2) { create(:product, account:) }
  let(:deal_product1) do
    create(:deal_product, deal:, product: product1, unit_amount_in_cents: 1000, total_amount_in_cents: 1000)
  end
  let(:deal_product2) do
    create(:deal_product, deal:, product: product2, unit_amount_in_cents: 2000, total_amount_in_cents: 2000)
  end
  let(:subject) { described_class.new(deal) }

  describe '#call' do
    before do
      deal.deal_products << deal_product1
      deal.deal_products << deal_product2
    end

    it 'recalculates deal within a transaction' do
      expect(deal).to receive(:save!).and_call_original

      subject.call

      expect(deal.total_deal_products_amount_in_cents).to eq(3000)
    end

    context 'when deal has no deal_products' do
      before { deal.deal_products.destroy_all }

      it 'sets deal total_deal_products_amount_in_cents to 0' do
        subject.call
        expect(deal.total_deal_products_amount_in_cents).to eq(0)
      end
    end
  end
end
