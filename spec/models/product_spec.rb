# == Schema Information
#
# Table name: products
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  amount_in_cents       :integer          default(0), not null
#  custom_attributes     :jsonb
#  description           :text             default(""), not null
#  identifier            :string           default(""), not null
#  name                  :string           default(""), not null
#  quantity_available    :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
require 'rails_helper'

RSpec.describe Product do
  let!(:account) { create(:account) }
  let(:product_first) { Product.first }
  describe 'create a product' do
    let(:new_product) { Product.new }
    context 'check amount_in_cents' do
      context 'when amount_in_cents is string' do
        it 'should convert amount_in_cents to integer and  create a product' do
          expect do
            product = new_product
            product.amount_in_cents = '100.580,30'
            product.account = account
            product.save
          end.to change(Product, :count).by(1)
          expect(product_first.amount_in_cents).to eq(10_058_030)
        end
        context 'when amount_in_cents is negative' do
          it 'should not create a product and return error' do
            expect do
              product = new_product
              product.amount_in_cents = '-100.580,30'
              product.account = account
              product.save
              expect(product.errors[:amount_in_cents]).to include('Can not be negative')
            end.to change(Product, :count).by(0)
          end
        end
      end
      context 'when amount_in_cents is integer' do
        it 'should create a product' do
          expect do
            product = new_product
            product.amount_in_cents = 10_058_030
            product.account = account
            product.save
          end.to change(Product, :count).by(1)
          expect(product_first.amount_in_cents).to eq(10_058_030)
        end
      end
    end
  end
end
