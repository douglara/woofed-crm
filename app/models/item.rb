class Item < ApplicationRecord
  belongs_to :deal
  belongs_to :contact
  belongs_to :account
  belongs_to :record, polymorphic: true
end
