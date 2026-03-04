require 'rails_helper'

RSpec.describe Deal::DragAndDropPosition do
  let!(:account)        { create(:account) }
  let!(:pipeline)       { create(:pipeline) }
  let!(:stage)          { create(:stage, pipeline:) }
  let!(:reference_deal) { create(:deal, stage:, position: 3) }

  describe '#initialize' do
    context 'when direction is invalid' do
      it 'raises ArgumentError' do
        expect do
          described_class.new(reference_deal:, direction: 'invalid')
        end.to raise_error(ArgumentError, 'invalid direction')
      end
    end

    it 'accepts nil, top and bottom (case insensitive)' do
      [nil, 'top', 'bottom', 'TOP', 'BOTTOM'].each do |dir|
        expect { described_class.new(reference_deal:, direction: dir) }.not_to raise_error
      end
    end
  end

  describe '#call' do
    context "direction: 'top' (reference is the card below the drop)" do
      it 'returns reference.position + 1' do
        position = described_class.new(reference_deal:, direction: 'top').call
        expect(position).to eq(4)
      end
    end

    context "direction: 'bottom' (reference is the card above the drop)" do
      it 'returns reference.position' do
        position = described_class.new(reference_deal:, direction: 'bottom').call
        expect(position).to eq(3)
      end
    end
  end
end
