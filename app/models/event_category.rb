# == Schema Information
#
# Table name: event_categories
#
#  id         :bigint           not null, primary key
#  name       :string           default(""), not null
#  icon       :string           default(""), not null
#  color      :string           default("#6857D9"), not null
#  account_id :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class EventCategory < ApplicationRecord
  belongs_to :account
  has_many :events, dependent: :nullify

  validates :name, presence: true
  validates :icon, presence: true
  validates :color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color code" }
end
