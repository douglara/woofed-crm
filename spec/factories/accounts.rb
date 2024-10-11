# == Schema Information
#
# Table name: accounts
#
#  id                  :bigint           not null, primary key
#  ai_usage            :jsonb            not null
#  name                :string           default(""), not null
#  number_of_employees :string           default("1-10"), not null
#  segment             :string           default("other"), not null
#  site_url            :string           default(""), not null
#  woofbot_auto_reply  :boolean          default(FALSE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
FactoryBot.define do
  factory :account do
    name { 'Account Testing' }
    site_url { 'https://woofedcrm.com' }

    before(:create) do |account, options|
      unless options.methods.include?(:run_embed_company_site) && options.run_embed_company_site
        account.define_singleton_method(:embed_company_site) { nil }
      end
    end
  end
end
