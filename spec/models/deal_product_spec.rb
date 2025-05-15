# == Schema Information
#
# Table name: deal_products
#
#  id                    :bigint           not null, primary key
#  product_identifier    :string           default(""), not null
#  product_name          :string           default(""), not null
#  quantity              :bigint           default(1), not null
#  total_amount_in_cents :bigint           default(0), not null
#  unit_amount_in_cents  :bigint           default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  deal_id               :bigint           not null
#  product_id            :bigint           not null
#
# Indexes
#
#  index_deal_products_on_deal_id     (deal_id)
#  index_deal_products_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (deal_id => deals.id)
#  fk_rails_...  (product_id => products.id)
#
# spec/models/deal_product_spec.rb
require 'rails_helper'

RSpec.describe DealProduct do
  let!(:account) { create(:account) }
  let!(:deal) { create(:deal, account:) }
  let!(:product) { create(:product, account:) }
  let!(:other_product) { create(:product, account:, identifier: 'prod_456', name: 'Other Product') }

  describe 'validations' do
    context 'validates uniqueness of product_id scoped to deal_id' do
      context 'valid' do
        it 'when product_id is unique for a deal_id' do
          create(:deal_product, deal:, product:)
          new_deal_product = build(:deal_product, deal:, product: other_product)

          expect(new_deal_product).to be_valid
        end
        it 'when product_id is reused in a different deal_id' do
          other_deal = create(:deal, account:)
          create(:deal_product, deal:, product:)
          new_deal_product = build(:deal_product, deal: other_deal, product:)

          expect(new_deal_product).to be_valid
        end
      end
      context 'invalid' do
        it 'when product_id is already taken for the same deal_id' do
          create(:deal_product, deal:, product:)
          new_deal_product = build(:deal_product, deal:, product:)

          expect(new_deal_product).to be_invalid
          expect(new_deal_product.errors[:product_id]).to include('has already been added to this deal')
        end
      end
    end
  end
end
