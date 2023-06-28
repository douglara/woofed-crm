# == Schema Information
#
# Table name: contacts_deals
#
#  id         :bigint           not null, primary key
#  main       :boolean          default(TRUE), not null
#  account_id :bigint
#  contact_id :bigint
#  deal_id    :bigint
#
# Indexes
#
#  contact_deal_index                  (contact_id,deal_id) UNIQUE
#  index_contacts_deals_on_account_id  (account_id)
#  index_contacts_deals_on_contact_id  (contact_id)
#  index_contacts_deals_on_deal_id     (deal_id)
#
class ContactsDeal < ApplicationRecord
  belongs_to :contact
  belongs_to :deal
end
