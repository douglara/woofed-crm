class App < ApplicationRecord
  belongs_to :account

  enum kind: { 'wpp_connect': 'wpp_connect' }
end
