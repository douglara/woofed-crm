# == Schema Information
#
# Table name: plugins
#
#  id         :string           not null, primary key
#  name       :string           not null
#  priority   :integer          default(0), not null
#  status     :string           default("active"), not null
#  version    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_plugins_on_status  (status)
#
FactoryBot.define do
  factory :plugin do
    sequence(:id) { |n| "plugin_id_#{n}" }
    sequence(:name) { |n| "plugin_#{n}" }
    status { "active" }
    version { "1.0.0" }
    priority { 0 }
  end
end
