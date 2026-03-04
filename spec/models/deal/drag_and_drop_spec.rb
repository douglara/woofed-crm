require 'rails_helper'

RSpec.describe Deal::DragAndDrop do
  let!(:account)  { create(:account) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage)    { create(:stage, pipeline:) }

  let!(:deal_pos1) { create(:deal, stage:, position: 1) }
  let!(:deal_pos2) { create(:deal, stage:, position: 2) }
  let!(:deal_pos3) { create(:deal, stage:, position: 3) }
  let!(:deal_pos4) { create(:deal, stage:, position: 4) }

  # Visual order on board (DESC): [ pos4 | pos3 | pos2 | pos1 ]

  def call(deal:, stage_id: stage.id, reference: nil, direction: nil)
    described_class.new(
      deal,
      stage_id: stage_id,
      element_reference_id: reference&.id,
      element_reference_drop_direction: direction
    ).call
  end

  describe '#call' do
    context 'same-stage move with reference' do
      context 'moving upward: drag deal_pos1 above deal_pos3' do
        # Before: [ pos4 | pos3 | pos2 | pos1 ]
        # direction 'top' → reference is the card below the drop (deal_pos3)
        # After:  [ pos4 | pos1 | pos3 | pos2 ]
        it 'places deal_pos1 at position 3, shifting deal_pos3 and deal_pos2 down' do
          call(deal: deal_pos1, reference: deal_pos3, direction: 'top')

          expect(deal_pos1.reload.position).to eq(3)
          expect(deal_pos3.reload.position).to eq(2)
          expect(deal_pos2.reload.position).to eq(1)
          expect(deal_pos4.reload.position).to eq(4)
        end
      end

      context 'moving downward: drag deal_pos4 below deal_pos2' do
        # Before: [ pos4 | pos3 | pos2 | pos1 ]
        # direction 'bottom' → reference is the card above the drop (deal_pos2)
        # After:  [ pos3 | pos2 | pos4 | pos1 ]
        it 'places deal_pos4 at position 2, shifting deal_pos3 up' do
          call(deal: deal_pos4, reference: deal_pos2, direction: 'bottom')

          expect(deal_pos4.reload.position).to eq(2)
          expect(deal_pos2.reload.position).to eq(3)
          expect(deal_pos3.reload.position).to eq(4)
          expect(deal_pos1.reload.position).to eq(1)
        end
      end

      context 'moving to the visual top: drag deal_pos1 above deal_pos4 (no topElement)' do
        # Before: [ pos4 | pos3 | pos2 | pos1 ]
        # bottomElement = deal_pos4, direction 'top' → insert_at(deal_pos4.position + 1)
        # After:  [ pos1 | pos4 | pos3 | pos2 ]
        it 'places deal_pos1 at the highest position, shifting all others down' do
          call(deal: deal_pos1, reference: deal_pos4, direction: 'top')

          expect(deal_pos1.reload.position).to eq(4)
          expect(deal_pos4.reload.position).to eq(3)
          expect(deal_pos3.reload.position).to eq(2)
          expect(deal_pos2.reload.position).to eq(1)
        end
      end

      context 'moving to the visual bottom: drag deal_pos4 below deal_pos1 (no bottomElement)' do
        # Before: [ pos4 | pos3 | pos2 | pos1 ]
        # topElement = deal_pos1, direction 'bottom' → insert_at(deal_pos1.position)
        # After:  [ pos3 | pos2 | pos1 | pos4 ]
        it 'places deal_pos4 at position 1, shifting all others up' do
          call(deal: deal_pos4, reference: deal_pos1, direction: 'bottom')

          expect(deal_pos4.reload.position).to eq(1)
          expect(deal_pos1.reload.position).to eq(2)
          expect(deal_pos2.reload.position).to eq(3)
          expect(deal_pos3.reload.position).to eq(4)
        end
      end
    end

    context 'cross-stage move with reference' do
      let!(:stage2)       { create(:stage, pipeline:) }
      let!(:s2_deal_pos1) { create(:deal, stage: stage2, position: 1) }
      let!(:s2_deal_pos2) { create(:deal, stage: stage2, position: 2) }
      let!(:s2_deal_pos3) { create(:deal, stage: stage2, position: 3) }

      # stage2 visual order: [ s2_pos3 | s2_pos2 | s2_pos1 ]

      context 'dropping above a card in the new stage: drag deal_pos2 above s2_deal_pos2' do
        # stage2 before: [ s2_pos3(3) | s2_pos2(2) | s2_pos1(1) ]
        # direction 'top' → reference is the card below the drop (s2_deal_pos2, pos: 2)
        # stage2 after:  [ s2_pos3(4) | deal_pos2(3) | s2_pos2(2) | s2_pos1(1) ]
        it 'inserts deal_pos2 at position 3 in stage2, shifting s2_deal_pos3 up' do
          call(deal: deal_pos2, stage_id: stage2.id, reference: s2_deal_pos2, direction: 'top')

          expect(deal_pos2.reload.stage_id).to eq(stage2.id)
          expect(deal_pos2.reload.position).to eq(3)
          expect(s2_deal_pos2.reload.position).to eq(2)
          expect(s2_deal_pos3.reload.position).to eq(4)
          expect(s2_deal_pos1.reload.position).to eq(1)
        end
      end

      context 'dropping below a card in the new stage: drag deal_pos2 below s2_deal_pos2' do
        # stage2 before: [ s2_pos3(3) | s2_pos2(2) | s2_pos1(1) ]
        # direction 'bottom' → reference is the card above the drop (s2_deal_pos2, pos: 2)
        # stage2 after:  [ s2_pos3(4) | s2_pos2(3) | deal_pos2(2) | s2_pos1(1) ]
        it 'inserts deal_pos2 at position 2 in stage2, shifting s2_deal_pos2 and s2_deal_pos3 up' do
          call(deal: deal_pos2, stage_id: stage2.id, reference: s2_deal_pos2, direction: 'bottom')

          expect(deal_pos2.reload.stage_id).to eq(stage2.id)
          expect(deal_pos2.reload.position).to eq(2)
          expect(s2_deal_pos2.reload.position).to eq(3)
          expect(s2_deal_pos3.reload.position).to eq(4)
          expect(s2_deal_pos1.reload.position).to eq(1)
        end
      end

      it 'closes the gap in the origin stage after the deal leaves' do
        call(deal: deal_pos2, stage_id: stage2.id, reference: s2_deal_pos1, direction: 'bottom')

        expect(deal_pos1.reload.position).to eq(1)
        expect(deal_pos3.reload.position).to eq(2)
        expect(deal_pos4.reload.position).to eq(3)
      end
    end

    context 'cross-stage move without reference (drop on empty column or column header)' do
      let!(:empty_stage) { create(:stage, pipeline:) }

      it 'moves the deal to the visual top of the new stage (position 1 in an empty stage)' do
        call(deal: deal_pos2, stage_id: empty_stage.id)

        expect(deal_pos2.reload.stage_id).to eq(empty_stage.id)
        expect(deal_pos2.reload.position).to eq(1)
      end

      it 'closes the gap in the origin stage' do
        call(deal: deal_pos2, stage_id: empty_stage.id)

        expect(deal_pos1.reload.position).to eq(1)
        expect(deal_pos3.reload.position).to eq(2)
        expect(deal_pos4.reload.position).to eq(3)
      end
    end

    context 'no reference and same stage (no-op)' do
      it 'does not change any positions' do
        call(deal: deal_pos2)

        expect(deal_pos1.reload.position).to eq(1)
        expect(deal_pos2.reload.position).to eq(2)
        expect(deal_pos3.reload.position).to eq(3)
        expect(deal_pos4.reload.position).to eq(4)
      end

      it 'returns the deal' do
        result = call(deal: deal_pos2)

        expect(result).to eq(deal_pos2)
      end
    end
  end
end
