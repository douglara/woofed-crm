# == Schema Information
#
# Table name: apps_evolution_apis
#
#  id                    :bigint           not null, primary key
#  active                :boolean
#  additional_attributes :jsonb
#  endpoint_url          :string
#  name                  :string
#  phone                 :string
#  status                :string
#  token                 :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#
# Indexes
#
#  index_apps_evolution_apis_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
require 'rails_helper'

RSpec.describe Event do
  context 'generate_token' do
    it 'should return a token' do
      evolution_api = Apps::EvolutionApi.new
      result = evolution_api.generate_token('token')
      expect(result.length).to eq(20)
    end
  end
end
