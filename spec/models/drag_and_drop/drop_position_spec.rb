require 'rails_helper'

RSpec.describe DragAndDrop::DropPosition do
  describe '#initialize' do
    it 'raises ArgumentError when element_reference_position is nil' do
      expect { described_class.new(element_reference_position: nil) }.to raise_error(ArgumentError, 'element_reference_position is required')
    end

    it 'raises ArgumentError when direction is invalid' do
      expect { described_class.new(element_reference_position: 1, element_reference_direction: 'invalid') }.to raise_error(ArgumentError, 'invalid direction')
    end

    it 'accepts nil direction' do
      expect { described_class.new(element_reference_position: 1, element_reference_direction: nil) }.not_to raise_error
    end

    it 'accepts bottom direction' do
      expect { described_class.new(element_reference_position: 1, element_reference_direction: 'bottom') }.not_to raise_error
    end

    it 'accepts top direction' do
      expect { described_class.new(element_reference_position: 1, element_reference_direction: 'top') }.not_to raise_error
    end

    it 'accepts direction case insensitive' do
      expect { described_class.new(element_reference_position: 1, element_reference_direction: 'BOTTOM') }.not_to raise_error
    end
  end

  describe '#call' do
    context 'without direction' do
      it 'returns same position when direction is nil' do
        result = described_class.new(element_reference_position: 5).call
        expect(result).to eq(5)
      end
    end

    context 'with bottom direction' do
      it 'returns position + 1' do
        result = described_class.new(element_reference_position: 3, element_reference_direction: 'bottom').call
        expect(result).to eq(4)
      end

      it 'returns position + 1 for position 1' do
        result = described_class.new(element_reference_position: 1, element_reference_direction: 'bottom').call
        expect(result).to eq(2)
      end
    end

    context 'with top direction' do
      it 'returns position - 1 when position > 1' do
        result = described_class.new(element_reference_position: 3, element_reference_direction: 'top').call
        expect(result).to eq(2)
      end

      it 'returns 1 when position is 1' do
        result = described_class.new(element_reference_position: 1, element_reference_direction: 'top').call
        expect(result).to eq(1)
      end

      it 'returns position - 1 for position 2' do
        result = described_class.new(element_reference_position: 2, element_reference_direction: 'top').call
        expect(result).to eq(1)
      end
    end

    context 'with string position' do
      it 'converts string position to integer' do
        result = described_class.new(element_reference_position: '5', element_reference_direction: 'bottom').call
        expect(result).to eq(6)
      end
    end
  end
end
