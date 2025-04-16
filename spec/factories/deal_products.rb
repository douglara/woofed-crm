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
FactoryBot.define do
  factory :deal_product do
    deal
    product
  end
end
