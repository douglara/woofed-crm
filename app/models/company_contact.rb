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
class CompanyContact < ApplicationRecord
  belongs_to :company
  belongs_to :contact

  validates :contact_id, uniqueness: { scope: :company_id }
end
