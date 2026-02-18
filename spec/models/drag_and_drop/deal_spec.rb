require 'rails_helper'

RSpec.describe DragAndDrop::Deal do
  let!(:account) { create(:account) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage1) { create(:stage, pipeline:) }
  let!(:stage2) { create(:stage, pipeline:) }
  let!(:deal) { create(:deal, stage: stage1, position: 2) }

  describe '#initialize' do
    it 'raises ArgumentError when deal is nil' do
      expect { described_class.new(deal: nil, deal_reference_position: 1) }.to raise_error(ArgumentError, 'deal is required')
    end

    it 'raises ArgumentError when deal_reference_position is nil' do
      expect { described_class.new(deal: deal, deal_reference_position: nil) }.to raise_error(ArgumentError, 'deal_reference_position is required')
    end

    it 'accepts valid parameters' do
      expect { described_class.new(deal: deal, deal_reference_position: 1) }.not_to raise_error
    end

    it 'accepts optional parameters' do
      expect { described_class.new(deal: deal, deal_reference_position: 1, deal_reference_direction: 'bottom', new_stage_id: stage2.id) }.not_to raise_error
    end
  end

  describe '#call' do
    let(:create_or_update_mock) { instance_double(Deal::CreateOrUpdate) }

    context 'moving within same stage' do
      before do
        allow(Deal::CreateOrUpdate).to receive(:new).and_return(create_or_update_mock)
        allow(create_or_update_mock).to receive(:call).and_return(deal)
      end

      it 'returns ok with deal result' do
        result = described_class.new(deal: deal, deal_reference_position: 3).call
        expect(result).to eq({ ok: deal })
      end

      it 'calls CreateOrUpdate with position only' do
        expect(Deal::CreateOrUpdate).to receive(:new).with(deal, { position: 3 })
        described_class.new(deal: deal, deal_reference_position: 3).call
      end

      it 'calculates position with bottom direction' do
        expect(Deal::CreateOrUpdate).to receive(:new).with(deal, { position: 4 })
        described_class.new(deal: deal, deal_reference_position: 3, deal_reference_direction: 'bottom').call
      end

      it 'calculates position with top direction' do
        expect(Deal::CreateOrUpdate).to receive(:new).with(deal, { position: 2 })
        described_class.new(deal: deal, deal_reference_position: 3, deal_reference_direction: 'top').call
      end
    end

    context 'moving between stages' do
      before do
        allow(Deal::CreateOrUpdate).to receive(:new).and_return(create_or_update_mock)
        allow(create_or_update_mock).to receive(:call).and_return(deal)
      end

      it 'calls CreateOrUpdate with stage_id and position' do
        expect(Deal::CreateOrUpdate).to receive(:new).with(deal, { stage_id: stage2.id, position: 1 })
        described_class.new(deal: deal, deal_reference_position: 1, new_stage_id: stage2.id).call
      end

      it 'does not include stage_id when same stage' do
        expect(Deal::CreateOrUpdate).to receive(:new).with(deal, { position: 1 })
        described_class.new(deal: deal, deal_reference_position: 1, new_stage_id: stage1.id).call
      end

      it 'calculates position with direction when moving between stages' do
        expect(Deal::CreateOrUpdate).to receive(:new).with(deal, { stage_id: stage2.id, position: 2 })
        described_class.new(deal: deal, deal_reference_position: 1, deal_reference_direction: 'bottom', new_stage_id: stage2.id).call
      end
    end

    context 'with string parameters' do
      before do
        allow(Deal::CreateOrUpdate).to receive(:new).and_return(create_or_update_mock)
        allow(create_or_update_mock).to receive(:call).and_return(deal)
      end

      it 'converts string position to integer' do
        expect(Deal::CreateOrUpdate).to receive(:new).with(deal, { position: 5 })
        described_class.new(deal: deal, deal_reference_position: '5').call
      end

      it 'converts string stage_id to integer' do
        expect(Deal::CreateOrUpdate).to receive(:new).with(deal, { stage_id: stage2.id, position: 3 })
        described_class.new(deal: deal, deal_reference_position: '3', new_stage_id: stage2.id.to_s).call
      end
    end
  end
end
