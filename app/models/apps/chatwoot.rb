class Apps::Chatwoot < ApplicationRecord
  include Applicable

  scope :actives, -> { where(active: true) }

  enum status: { 
    'inactive': 'inactive',
    'active': 'active',
    'sync': 'sync',
    'pair': 'pair',
  }

  after_create_commit do
    self.update(embedding_token: generate_token)
  end

  def generate_token
    loop do
      token = SecureRandom.hex(10)
      break token unless Apps::Chatwoot.where(embedding_token: token).exists?
    end
  end
end