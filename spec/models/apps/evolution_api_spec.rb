# == Schema Information
#
# Table name: apps_evolution_apis
#
#  id                    :bigint           not null, primary key
#  active                :boolean          default(TRUE), not null
#  additional_attributes :jsonb
#  connection_status     :string           default("disconnected"), not null
#  endpoint_url          :string           default(""), not null
#  instance              :string           default(""), not null
#  name                  :string           default(""), not null
#  phone                 :string           default(""), not null
#  qrcode                :string           default(""), not null
#  token                 :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
require 'rails_helper'

RSpec.describe Apps::EvolutionApi do

end
