# frozen_string_literal: true

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
class Plugin < ApplicationRecord
  STATUSES = %w[active inactive failed].freeze

  validates :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }

  def local_path
    Rails.root.join("storage", "plugins", id)
  end

  def installed_locally?
    local_path.exist?
  end
end
