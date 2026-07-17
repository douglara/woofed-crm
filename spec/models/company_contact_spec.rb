# == Schema Information
#
# Table name: company_contacts
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  contact_id :bigint           not null
#
# Indexes
#
#  index_company_contacts_on_company_id                 (company_id)
#  index_company_contacts_on_company_id_and_contact_id  (company_id,contact_id) UNIQUE
#  index_company_contacts_on_contact_id                 (contact_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (contact_id => contacts.id)
#
require 'rails_helper'

RSpec.describe CompanyContact do
  let!(:account) { create(:account) }
  let!(:company) { create(:company) }
  let!(:contact) { create(:contact) }

  describe 'validations' do
    context 'validates contact_id' do
      context 'valid' do
        it 'when the contact is not linked to the company yet' do
          new_company_contact = build(:company_contact, company:, contact:)

          expect(new_company_contact.save).to be_truthy
        end

        it 'when the same contact is linked to another company' do
          create(:company_contact, company:, contact:)
          new_company_contact = build(:company_contact, company: create(:company), contact:)

          expect(new_company_contact.save).to be_truthy
        end

        it 'when the same company is linked to another contact' do
          create(:company_contact, company:, contact:)
          new_company_contact = build(:company_contact, company:, contact: create(:contact))

          expect(new_company_contact.save).to be_truthy
        end
      end

      context 'invalid' do
        it 'when the contact is already linked to the company' do
          create(:company_contact, company:, contact:)
          new_company_contact = build(:company_contact, company:, contact:)

          expect(new_company_contact.save).to be_falsey
          expect(new_company_contact.errors[:contact_id]).to include('has already been taken')

          expect { new_company_contact.save!(validate: false) }
            .to raise_error(ActiveRecord::RecordNotUnique)
        end

        it 'when company is missing' do
          new_company_contact = build(:company_contact, company: nil, contact:)

          expect(new_company_contact).to be_invalid
          expect(new_company_contact.errors[:company]).to include('must exist')
        end

        it 'when contact is missing' do
          new_company_contact = build(:company_contact, company:, contact: nil)

          expect(new_company_contact).to be_invalid
          expect(new_company_contact.errors[:contact]).to include('must exist')
        end
      end
    end
  end
end
