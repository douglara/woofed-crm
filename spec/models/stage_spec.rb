require 'rails_helper'

RSpec.describe Stage do
  context 'scopes' do
    let(:account) { create(:account) }
    let!(:pipeline) { create(:pipeline, account:) }
    let!(:stage) { create(:stage, account:, pipeline:) }
    let!(:another_stage) { create(:stage, account:, pipeline:, name: 'Stage 2') }
    let!(:deal_open_1) { create(:deal, account:, stage:, total_deal_products_amount_in_cents: '6', status: 'open') }
    let!(:deal_open_2) { create(:deal, account:, stage:, total_deal_products_amount_in_cents: '8', status: 'open') }
    let!(:deal_open_3) { create(:deal, account:, stage:, total_deal_products_amount_in_cents: '7', status: 'open') }
    let!(:deal_lost_1) { create(:deal, account:, stage:, total_deal_products_amount_in_cents: '8', status: 'lost') }
    let!(:deal_lost_2) { create(:deal, account:, stage:, total_deal_products_amount_in_cents: '8', status: 'lost') }
    let!(:deal_from_another_stage) do
      create(:deal, account:, stage: another_stage, total_deal_products_amount_in_cents: '7')
    end
    describe '#total_amount_deals' do
      it 'status open' do
        expect(stage.total_amount_deals('open')).to be 21
      end
      it 'status lost' do
        expect(stage.total_amount_deals('lost')).to be 16
      end
      it 'status all' do
        expect(stage.total_amount_deals('all')).to be 37
      end
    end

    describe '#total_quantity_deals' do
      it 'status open' do
        expect(stage.total_quantity_deals('open')).to be 3
      end
      it 'status lost' do
        expect(stage.total_quantity_deals('lost')).to be 2
      end
      it 'status all' do
        expect(stage.total_quantity_deals('all')).to be 5
      end
    end
  end
end
