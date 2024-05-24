# == Schema Information
#
# Table name: accounts
#
#  id                 :bigint           not null, primary key
#  ai_usage           :jsonb            not null
#  name               :string           default(""), not null
#  site_url           :string           default(""), not null
#  woofbot_auto_reply :boolean          default(FALSE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class Account < ApplicationRecord
  validates :name, presence: true
  validates :name, length: { maximum: 255 }
  has_many :events, dependent: :destroy_async
  has_many :apps, dependent: :destroy_async
  has_many :users, dependent: :destroy_async
  has_many :contacts, dependent: :destroy_async
  has_many :deals, dependent: :destroy_async
  has_many :custom_attribute_definitions
  has_many :custom_attributes_definitions, class_name: 'CustomAttributeDefinition', dependent: :destroy_async
  has_many :apps_wpp_connects, class_name: 'Apps::WppConnect'
  has_many :apps_chatwoots, class_name: 'Apps::Chatwoot'
  has_many :apps_evolution_apis, class_name: 'Apps::EvolutionApi'
  has_many :webhooks, dependent: :destroy
  has_many :pipelines, dependent: :destroy
  has_many :stages, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :embedding_documments, dependent: :destroy
  has_many :deal_products, dependent: :destroy

  after_create :embed_company_site

  def site_url=(url)
    super(normalize_url(url))
  end

  def normalize_url(url)
    url = "https://#{url}" unless url.match?(%r{\Ahttp(s)?://})

    url
  end

  def embed_company_site
    Accounts::Create::EmbedCompanySiteJob.perform_later(id) if site_url.present? && ai_active?
  end

  def ai_active?
    ENV['OPENAI_API_KEY'].present?
  end

  def exceeded_account_limit?
    ai_usage['tokens'] >= ai_usage['limit']
  end
end
