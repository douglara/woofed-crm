# frozen_string_literal: true

# == Schema Information
#
# Table name: plugins
#
#  id         :bigint           not null, primary key
#  commit_sha :string
#  github_url :string
#  name       :string           not null
#  status     :string           default("active"), not null
#  version    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_plugins_on_name  (name) UNIQUE
#
# Tracks plugins registered in the system.
# status:
#   active    - installed locally and enabled
#   inactive  - disabled (kept in DB but not loaded)
#   failed    - clone/load failed
class Plugin < ApplicationRecord
  STATUSES = %w[active inactive failed].freeze

  validates :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :github_url, format: {
    with: %r{\Ahttps://github\.com/[\w.\-]+/[\w.\-]+(?:\.git)?\z},
    message: "must be a public GitHub HTTPS URL"
  }, allow_blank: true

  scope :active, -> { where(status: "active") }

  def local_path
    Rails.root.join("storage", "plugins", name)
  end

  def installed_locally?
    local_path.exist?
  end
end
