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
class Product < ApplicationRecord
  include Product::Broadcastable
  include Product::Presenters
  include CustomAttributes

  has_many :attachments, as: :attachable
  validates :quantity_available, :amount_in_cents,
            numericality: { greater_than_or_equal_to: 0, message: 'Can not be negative' }
  has_many :deal_products, dependent: :destroy
  accepts_nested_attributes_for :attachments, reject_if: :all_blank, allow_destroy: true

  FORM_FIELDS = %i[name amount_in_cents quantity_available identifier]

  SHOW_FIELDS = { details: %i[name amount_in_cents_at_format quantity_available identifier description custom_attributes created_at
                              updated_at] }.freeze

  %i[image file video].each do |file_type|
    define_method "#{file_type}_attachments" do
      attachments.by_file_type(file_type)
    end
  end

  def self.ransackable_associations(auth_object = nil)
    %w[account attachments deal_products]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[identifier amount_in_cents quantity_available description name created_at updated_at]
  end

  def amount_in_cents=(amount)
    amount = sanitize_amount(amount)
    super(amount)
  end
end
