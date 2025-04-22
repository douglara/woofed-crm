# == Schema Information
#
# Table name: apps_ai_assistents
#
#  id         :bigint           not null, primary key
#  api_key    :string           default(""), not null
#  auto_reply :boolean          default(FALSE), not null
#  enabled    :boolean          default(FALSE), not null
#  model      :string           default("gpt-4o"), not null
#  usage      :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :apps_ai_assistent, class: 'Apps::AiAssistent' do
    api_key { 'API-Key' }
  end
end
