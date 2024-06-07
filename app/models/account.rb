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

  def events
    Event.all
  end

  def apps
    App.all
  end

  def users
    User.all
  end

  def contacts
    Contact.all
  end

  def deals
    Deal.all
  end

  def custom_attribute_definitions
    CustomAttributeDefinition.all
  end

  def custom_attributes_definitions
    custom_attribute_definitions
  end

  def apps_wpp_connects
    Apps::WppConnect.all
  end

  def apps_chatwoots
    Apps::Chatwoot.all
  end

  def apps_evolution_apis
    Apps::EvolutionApi.all
  end

  def webhooks
    Webhook.all
  end

  def stages
    Stage.all
  end

  def products
    Product.all
  end

  def embedding_documments
    EmbeddingDocumment.all
  end

  def deal_products
    DealProduct.all
  end

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
