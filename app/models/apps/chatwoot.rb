# == Schema Information
#
# Table name: apps_chatwoots
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(FALSE), not null
#  embedding_token :string           default(""), not null
#  endpoint_url    :string           default(""), not null
#  name            :string
#  user_token      :string           default(""), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint
#
# Indexes
#
#  index_apps_chatwoots_on_account_id  (account_id)
#
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
