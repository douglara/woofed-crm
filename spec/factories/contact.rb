FactoryBot.define do
  factory :contact do
    account
    full_name { 'Tim Maia' }
    email { 'tim@maia.com' }
    phone { '+5541988443322' }
  end
end
