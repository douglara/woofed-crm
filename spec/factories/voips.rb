# == Schema Information
#
# Table name: voips
#
#  id               :bigint           not null, primary key
#  name             :string           default(""), not null
#  password         :string           default(""), not null
#  server           :string           default(""), not null
#  user_name        :string           default(""), not null
#  websocket_server :string           default(""), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_voips_on_user_id  (user_id)
#
FactoryBot.define do
  factory :voip do
    username { "MyString" }
    password { "MyString" }
  end
end
