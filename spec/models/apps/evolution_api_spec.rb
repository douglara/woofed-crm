# == Schema Information
#
# Table name: apps_evolution_apis
#
#  id                    :bigint           not null, primary key
#  active                :boolean          default(TRUE), not null
#  additional_attributes :jsonb
#  connection_status     :string           default("inactive"), not null
#  endpoint_url          :string           default(""), not null
#  instance              :string           default(""), not null
#  name                  :string           default(""), not null
#  phone                 :string           default(""), not null
#  token                 :string           default(""), not null
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
