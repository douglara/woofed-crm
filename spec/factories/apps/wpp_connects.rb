# == Schema Information
#
# Table name: apps_wpp_connects
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(FALSE), not null
#  endpoint_url :string           default(""), not null
#  name         :string
#  secretkey    :string           default(""), not null
#  session      :string           default(""), not null
#  status       :string           default("inactive"), not null
#  token        :string           default(""), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint
#
# Indexes
#
#  index_apps_wpp_connects_on_account_id  (account_id)
#
FactoryBot.define do
  factory :apps_wpp_connect, class: 'Apps::WppConnect' do
    name { 'Connection testing' }
    status { 'active' }
    active { true }
    session { 'session_testing' }
    token { 'token' }
    endpoint_url { 'http://localhost:3002' }
    secretkey { 'secretkey' }
    account
  end
end
