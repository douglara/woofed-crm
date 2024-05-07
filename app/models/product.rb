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
class Product < ApplicationRecord
  include Product::Broadcastable
  include Product::Presenters
  belongs_to :account
  has_many :attachment, as: :attachable
  attribute :invalid_files
  attribute :files, default: []
  validates :quantity_available, :amount_in_cents,
            numericality: { greater_than_or_equal_to: 0, message: 'Can not be negative' }
  validate :validate_invalid_files
  has_many :deal_products
  FORM_FIELDS = %i[name amount_in_cents quantity_available identifier]

  def amount_in_cents=(amount)
    amount = amount.gsub(/[^\d-]/, '').to_i if amount.is_a?(String)
    super
  end

  def validate_invalid_files
    errors.add(:files, 'Invalid files') if invalid_files == true
  end
end
