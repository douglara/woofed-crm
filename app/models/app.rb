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
#
class App < ApplicationRecord
  enum kind: { 'wpp_connect': 'wpp_connect' }
end
