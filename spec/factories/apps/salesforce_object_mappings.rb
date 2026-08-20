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
      # A Woofed deal has no free-form amount column -- what it shows comes from
      # its products -- so an Opportunity's Amount lands in a custom attribute.
      field_mappings do
        [
          { 'salesforce_field' => 'Name', 'woofed_field' => 'name', 'kind' => 'attribute' },
          { 'salesforce_field' => 'Amount', 'woofed_field' => 'valor', 'kind' => 'custom_attribute' }
        ]
      end
    end
  end
end
