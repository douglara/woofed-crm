# == Schema Information
#
# Table name: accounts
#
#  id                  :bigint           not null, primary key
#  ai_usage            :jsonb            not null
#  name                :string           default(""), not null
#  number_of_employees :string           default("1-10"), not null
#  segment             :string           default("other"), not null
#  site_url            :string           default(""), not null
#  woofbot_auto_reply  :boolean          default(FALSE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class Account < ApplicationRecord
  validates :name, presence: true
  validates :name, length: { maximum: 255 }

  enum segment: {
    technology: 'technology',
    health: 'health',
    finance: 'finance',
    education: 'education',
    retail: 'retail',
    services: 'services',
    manufacturing: 'manufacturing',
    telecommunications: 'telecommunications',
    transportation_logistics: 'transportation_logistics',
    real_estate: 'real_estate',
    energy: 'energy',
    agriculture: 'agriculture',
    tourism_hospitality: 'tourism_hospitality',
    entertainment_media: 'entertainment_media',
    construction: 'construction',
    public_sector: 'public_sector',
    consulting: 'consulting',
    startup: 'startup',
    ecommerce: 'ecommerce',
    security: 'security',
    automotive: 'automotive',
    other: 'other'
  }
  enum number_of_employees: {
    '1-10' => '1-10',
    '11-50' => '11-50',
    '51-200' => '51-200',
    '201-500' => '201-500',
    '501+' => '501+'
  }

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

  def apps_ai_assistents
    Apps::AiAssistent.all
  end

  def site_url=(url)
    super(normalize_url(url))
  end

  def normalize_url(url)
    url = "https://#{url}" unless url.match?(%r{\Ahttp(s)?://})

    url
  end
end
