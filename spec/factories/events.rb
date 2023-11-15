FactoryBot.define do
  factory :event do
    account
    contact
    deal
    title { 'Event 1' }
    content { 'Hi Lorena' }
  end
end
