require 'rails_helper'

RSpec.describe Deal::CreateOrUpdate do
  let(:account) { create(:account) }
  let(:deal) { build(:deal, account:, status: :open) }
  let(:params) { { status: 'won' } }
  let(:subject) { described_class.new(deal, params) }

  describe '#call' do
    context 'when the deal is valid' do
      context 'creating a new deal' do
        context 'with status won' do
          let(:params) { { status: 'won' } }

          it 'creates the deal and sets won_at to the current time' do
            expect(subject.call).to eq(deal)
            expect(deal).to be_persisted
            expect(deal.status).to eq('won')
            expect(deal.won_at).to be_a(Time)
            expect(deal.lost_at).to be_nil
          end
        end

        context 'with status lost' do
          let(:params) { { status: 'lost' } }

          it 'creates the deal and sets lost_at to the current time' do
            expect(subject.call).to eq(deal)
            expect(deal).to be_persisted
            expect(deal.status).to eq('lost')
            expect(deal.lost_at).to be_a(Time)
            expect(deal.won_at).to be_nil
          end
        end

        context 'with status open' do
          let(:params) { { status: 'open' } }

          it 'creates the deal and sets lost_at and won_at to nil' do
            expect(subject.call).to eq(deal)
            expect(deal).to be_persisted
            expect(deal.status).to eq('open')
            expect(deal.won_at).to be_nil
            expect(deal.lost_at).to be_nil
          end
        end
      end

      context 'updating an existing deal' do
        let(:deal) { create(:deal, account:, status: :open) }

        context 'when status changes to won' do
          let(:params) { { status: 'won' } }

          it 'updates the deal and sets won_at to the current time' do
            expect(subject.call).to eq(deal)
            expect(deal.status).to eq('won')
            expect(deal.won_at).to be_a(Time)
            expect(deal.lost_at).to be_nil
          end
        end

        context 'when status changes to lost' do
          let(:params) { { status: 'lost' } }

          it 'updates the deal and sets lost_at to the current time' do
            expect(subject.call).to eq(deal)
            expect(deal.status).to eq('lost')
            expect(deal.lost_at).to be_a(Time)
            expect(deal.won_at).to be_nil
          end
        end

        context 'when status changes to open' do
          let(:deal) { create(:deal, account:, status: :won, won_at: Time.parse('2025-05-01 10:00:00 UTC')) }
          let(:params) { { status: 'open' } }

          it 'updates the deal and clears lost_at and won_at' do
            expect(subject.call).to eq(deal)
            expect(deal.status).to eq('open')
            expect(deal.won_at).to be_nil
            expect(deal.lost_at).to be_nil
          end
        end

        context 'when status does not change' do
          let(:deal) { create(:deal, account:, status: :won, won_at: Time.parse('2025-05-01 10:00:00 UTC')) }
          let(:params) { { name: 'Updated Name' } }

          it 'updates the deal and does not modify won_at or lost_at' do
            expect(subject.call).to eq(deal)
            expect(deal.name).to eq('Updated Name')
            expect(deal.status).to eq('won')
            expect(deal.won_at).to eq(Time.parse('2025-05-01 10:00:00 UTC'))
            expect(deal.lost_at).to be_nil
          end
        end
      end
    end

    context 'when the deal is invalid' do
      let(:params) { { status: nil } }

      skip 'returns false and does not save the deal' do
        expect(subject.call).to eq(false)
        expect(deal).not_to be_persisted
      end
    end
  end

  describe '#should_update_lost_at_or_won_at?' do
    context 'when deal is new' do
      let(:deal) { build(:deal, account:) }

      it 'returns true' do
        instance = described_class.new(deal, params)
        deal.assign_attributes(params)
        expect(instance.send(:should_update_lost_at_or_won_at?)).to eq(true)
      end
    end

    context 'when status changes' do
      let(:deal) { create(:deal, account:, status: :open) }
      let(:params) { { status: 'won' } }

      it 'returns true' do
        instance = described_class.new(deal, params)
        deal.assign_attributes(params)
        expect(instance.send(:should_update_lost_at_or_won_at?)).to eq(true)
      end
    end

    context 'when status does not change' do
      let(:deal) { create(:deal, account:, status: :won) }
      let(:params) { { name: 'Updated Name' } }

      it 'returns false' do
        instance = described_class.new(deal, params)
        deal.assign_attributes(params)
        expect(instance.send(:should_update_lost_at_or_won_at?)).to eq(false)
      end
    end
  end
end
