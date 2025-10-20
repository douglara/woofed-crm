# == Schema Information
#
# Table name: accounts
#
#  id                  :bigint           not null, primary key
#  ai_usage            :jsonb            not null
#  currency_code       :string           default("BRL"), not null
#  name                :string           default(""), not null
#  number_of_employees :string           default("1-10"), not null
#  segment             :string           default("other"), not null
#  settings            :jsonb            not null
#  site_url            :string           default(""), not null
#  woofbot_auto_reply  :boolean          default(FALSE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'rails_helper'
RSpec.describe Account do
  describe 'validations' do
    context 'validates currency_code' do
      context 'valid' do
        it 'when currency_code is an ISO 4217 code' do
          new_account = build(:account, currency_code: 'USD')

          expect(new_account).to be_valid
        end
      end

      context 'invalid' do
        it 'when currency_code is not an ISO 4217 code' do
          new_account = build(:account, currency_code: 'xpto')

          expect(new_account).to be_invalid
          expect(new_account.errors[:currency_code]).to match_array([I18n.t('errors.messages.inclusion')])

          expect { new_account.save! }
            .to raise_error(ActiveRecord::RecordInvalid)
        end

        it 'when currency_code is blank' do
          new_account = build(:account, currency_code: '')

          expect(new_account).to be_invalid
          expect(new_account.errors[:currency_code]).to include(I18n.t('errors.messages.blank'))

          expect { new_account.save! }
            .to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end

  describe '#deal_free_form_lost_reasons' do
    let(:account) { create(:account, deal_free_form_lost_reasons: true) }

    context 'when there are no DealLostReason records' do
      before { DealLostReason.destroy_all }

      it 'returns false' do
        expect(account.deal_free_form_lost_reasons).to eq(false)
      end
    end

    context 'when there are DealLostReason records' do
      let!(:deal_lost_reason) { create(:deal_lost_reason) }

      it 'returns the stored value' do
        expect(account.deal_free_form_lost_reasons).to eq(true)
      end
    end
  end
end
