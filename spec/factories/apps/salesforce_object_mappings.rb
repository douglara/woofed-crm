FactoryBot.define do
  factory :apps_salesforce_object_mappings, class: 'Apps::Salesforce::ObjectMapping' do
    app factory: :apps_salesforces
    salesforce_object { 'Account' }
    woofed_model { 'Company' }
    enabled { true }
    field_mappings do
      [
        { 'salesforce_field' => 'Name', 'woofed_field' => 'name', 'kind' => 'attribute' },
        { 'salesforce_field' => 'Phone', 'woofed_field' => 'phone', 'kind' => 'attribute' }
      ]
    end

    trait :disabled do
      enabled { false }
    end

    trait :opportunity do
      salesforce_object { 'Opportunity' }
      woofed_model { 'Deal' }
      field_mappings do
        [{ 'salesforce_field' => 'Amount', 'woofed_field' => 'total_amount_in_cents',
           'kind' => 'attribute', 'transform' => 'currency_to_cents' }]
      end
    end
  end
end
