class FlowItems::ActivitiesKinds::WpConnect < ApplicationRecord
  self.table_name = 'wp_connects'
  
  scope :enabled, -> { where(enabled: true) }

  def icon_key
    'fab fa-whatsapp'
  end
end
