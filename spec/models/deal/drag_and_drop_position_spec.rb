require 'rails_helper'

RSpec.describe Deal::DragAndDropPosition do
  subject { described_class.new(deal_reference_position:, deal_reference_direction:) }

  describe '#initialize' do
    context 'when deal_reference_position is nil' do
      let(:deal_reference_position) { nil }
      let(:deal_reference_direction) { 'bottom' }

      it 'raises ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'deal_reference_position is required')
      end
    end

    context 'when direction is invalid' do
      let(:deal_reference_position) { 1 }
      let(:deal_reference_direction) { 'invalid' }

      it 'raises ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'invalid direction')
      end
    end

    context 'when direction is nil' do
      let(:deal_reference_position) { 1 }
      let(:deal_reference_direction) { nil }

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when direction is bottom' do
      let(:deal_reference_position) { 1 }
      let(:deal_reference_direction) { 'bottom' }

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when direction is top' do
      let(:deal_reference_position) { 1 }
      let(:deal_reference_direction) { 'top' }

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when direction is uppercase' do
      let(:deal_reference_position) { 1 }
      let(:deal_reference_direction) { 'BOTTOM' }

      it 'accepts direction case insensitive' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe '#call' do
    context 'without direction' do
      let(:deal_reference_position) { 5 }
      let(:deal_reference_direction) { nil }

      it 'returns same position' do
        expect(subject.call).to eq(5)
      end
    end

    context 'with bottom direction' do
      let(:deal_reference_direction) { 'bottom' }

      context 'when position is 3' do
        let(:deal_reference_position) { 3 }

        it 'returns position + 1' do
          expect(subject.call).to eq(4)
        end
      end

      context 'when position is 1' do
        let(:deal_reference_position) { 1 }

        it 'returns position + 1' do
          expect(subject.call).to eq(2)
        end
      end
    end

    context 'with top direction' do
      let(:deal_reference_direction) { 'top' }

      context 'when position > 1' do
        let(:deal_reference_position) { 3 }

        it 'returns position - 1' do
          expect(subject.call).to eq(2)
        end
      end

      context 'when position is 1' do
        let(:deal_reference_position) { 1 }

        it 'returns 1' do
          expect(subject.call).to eq(1)
        end
      end
    end

    context 'with string position' do
      let(:deal_reference_position) { '5' }
      let(:deal_reference_direction) { 'bottom' }

      it 'converts string position to integer' do
        expect(subject.call).to eq(6)
      end
    end
  end
end
