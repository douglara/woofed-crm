# == Schema Information
#
# Table name: products
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  amount                :integer          default(0), not null
#  custom_attributes     :jsonb
#  description           :string           default(""), not null
#  identifier            :string           default(""), not null
#  name                  :string           default(""), not null
#  quantity_available    :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#
# Indexes
#
#  index_products_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
require 'rails_helper'

RSpec.describe Product, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
