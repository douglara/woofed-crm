# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  avatar_url             :string           default(""), not null
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  full_name              :string           default(""), not null
#  job_description        :string           default("other"), not null
#  language               :string           default("en"), not null
#  notifications          :jsonb            not null
#  phone                  :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  has_one :installation
  has_many :webpush_subscriptions
  has_many :deal_assignees, dependent: :destroy
  has_many :deals, through: :deal_assignees
  has_many :created_deals,
           class_name: 'Deal',
           foreign_key: 'created_by_id',
           dependent: :nullify,
           inverse_of: :creator
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  accepts_nested_attributes_for :account

  attribute :language, :string, default: ENV.fetch('LANGUAGE', 'en')

  validates :phone,
            allow_blank: true,
            format: { with: /\+[1-9]\d{1,14}\z/ }
  store :notifications, accessors: [
    :webpush_notify_on_event_expired
  ], coder: JSON

  enum job_description: {
    ceo: 'ceo',
    cfo: 'cfo',
    cto: 'cto',
    project_manager: 'project_manager',
    software_engineer: 'software_engineer',
    marketing_manager: 'marketing_manager',
    sales_representative: 'sales_representative',
    hr_specialist: 'hr_specialist',
    customer_support: 'customer_support',
    product_manager: 'product_manager',
    operations_manager: 'operations_manager',
    business_development_manager: 'business_development_manager',
    data_analyst: 'data_analyst',
    account_manager: 'account_manager',
    consultant: 'consultant',
    financial_analyst: 'financial_analyst',
    graphic_designer: 'graphic_designer',
    ux_ui_designer: 'ux_ui_designer',
    content_creator: 'content_creator',
    legal_counsel: 'legal_counsel',
    research_scientist: 'research_scientist',
    it_administrator: 'it_administrator',
    system_administrator: 'system_administrator',
    project_coordinator: 'project_coordinator',
    operations_coordinator: 'operations_coordinator',
    executive_assistant: 'executive_assistant',
    other: 'other'
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[full_name email created_at updated_at phone language job_description id
       avatar_url]
  end

  def get_jwt_token
    Users::JsonWebToken.encode_user(self)
  end

  def webpush_notify_on_event_expired=(value)
    self[:notifications][:webpush_notify_on_event_expired] = ActiveRecord::Type::Boolean.new.cast(value)
  end
end
