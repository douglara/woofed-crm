# == Schema Information
#
# Table name: apps
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(FALSE), not null
#  kind       :string
#  name       :string
#  settings   :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint
#
# Indexes
#
#  index_apps_on_account_id  (account_id)
#
class App < ApplicationRecord
  belongs_to :account

  enum kind: { 'wpp_connect': 'wpp_connect' }
end
