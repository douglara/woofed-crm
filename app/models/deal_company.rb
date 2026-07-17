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
class DealCompany < ApplicationRecord
  belongs_to :deal
  belongs_to :company

  validates :company_id, uniqueness: { scope: :deal_id }
end
