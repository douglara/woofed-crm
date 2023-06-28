# == Schema Information
#
# Table name: wp_connects
#
#  id           :bigint           not null, primary key
#  enabled      :boolean          default(FALSE), not null
#  endpoint_url :string           default(""), not null
#  name         :string           default(""), not null
#  secretkey    :string           default(""), not null
#  session      :string           default(""), not null
#  token        :string           default(""), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class FlowItems::ActivitiesKinds::WpConnect < ApplicationRecord
  self.table_name = 'wp_connects'
  
  scope :enabled, -> { where(enabled: true) }

  def icon_key
    'fab fa-whatsapp'
  end
end
