# == Schema Information
#
# Table name: installations
#
#  id                :string           not null, primary key
#  app_private_key   :string
#  server_public_key :string
#  token             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :installation do
    server_public_key { "MyString" }
    app_private_key { "MyString" }
    token { "MyString" }
  end
end
