# == Schema Information
#
# Table name: deal_companies
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  deal_id    :bigint           not null
#
# Indexes
#
#  index_deal_companies_on_company_id              (company_id)
#  index_deal_companies_on_deal_id                 (deal_id)
#  index_deal_companies_on_deal_id_and_company_id  (deal_id,company_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (deal_id => deals.id)
#
require 'rails_helper'

RSpec.describe DealCompany do
  let!(:account) { create(:account) }
  let!(:deal) { create(:deal) }
  let!(:company) { create(:company) }

  describe 'validations' do
    context 'validates company_id' do
      context 'valid' do
        it 'when the company is not linked to the deal yet' do
          new_deal_company = build(:deal_company, deal:, company:)

          expect(new_deal_company.save).to be_truthy
        end

        it 'when the same company is linked to another deal' do
          create(:deal_company, deal:, company:)
          new_deal_company = build(:deal_company, deal: create(:deal), company:)

          expect(new_deal_company.save).to be_truthy
        end

        it 'when the same deal is linked to another company' do
          create(:deal_company, deal:, company:)
          new_deal_company = build(:deal_company, deal:, company: create(:company))

          expect(new_deal_company.save).to be_truthy
        end
      end

      context 'invalid' do
        it 'when the company is already linked to the deal' do
          create(:deal_company, deal:, company:)
          new_deal_company = build(:deal_company, deal:, company:)

          expect(new_deal_company.save).to be_falsey
          expect(new_deal_company.errors[:company_id]).to include('has already been taken')

          expect { new_deal_company.save!(validate: false) }
            .to raise_error(ActiveRecord::RecordNotUnique)
        end

        it 'when deal is missing' do
          new_deal_company = build(:deal_company, deal: nil, company:)

          expect(new_deal_company).to be_invalid
          expect(new_deal_company.errors[:deal]).to include('must exist')
        end

        it 'when company is missing' do
          new_deal_company = build(:deal_company, deal:, company: nil)

          expect(new_deal_company).to be_invalid
          expect(new_deal_company.errors[:company]).to include('must exist')
        end
      end
    end
  end

  describe 'associations' do
    it 'links a deal to many companies and a company to many deals' do
      other_company = create(:company, name: 'Other company')
      other_deal = create(:deal, name: 'Other deal')
      create(:deal_company, deal:, company:)
      create(:deal_company, deal:, company: other_company)
      create(:deal_company, deal: other_deal, company:)

      expect(deal.companies).to contain_exactly(company, other_company)
      expect(company.deals).to contain_exactly(deal, other_deal)
    end

    it 'has no companies when none are linked' do
      expect(deal.companies).to be_empty
      expect(company.deals).to be_empty
    end

    it 'destroys the join records but keeps the companies when a deal is destroyed' do
      create(:deal_company, deal:, company:)

      expect { deal.destroy }.to change(described_class, :count).by(-1)
      expect(company.reload).to be_persisted
    end

    it 'destroys the join records but keeps the deals when a company is destroyed' do
      create(:deal_company, deal:, company:)

      expect { company.destroy }.to change(described_class, :count).by(-1)
      expect(deal.reload).to be_persisted
    end
  end
end
