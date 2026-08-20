require 'rails_helper'

RSpec.describe Inertia::Accounts::Apps::Salesforces::ObjectMappingsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:base_url) { "/accounts/#{account.id}/apps/salesforce" }
  let(:mapping_params) do
    {
      object_mapping: {
        salesforce_object: 'Account',
        woofed_model: 'Company',
        enabled: true,
        field_mappings: [
          { salesforce_field: 'Name', woofed_field: 'name', kind: 'attribute' },
          { salesforce_field: 'Industria__c', woofed_field: 'industria', kind: 'custom_attribute' }
        ]
      }
    }
  end

  before { sign_in(user) }

  describe 'POST /accounts/{account.id}/apps/salesforce/object_mappings' do
    context 'when the object was never mapped' do
      let!(:salesforce) { create(:apps_salesforces, :connected) }

      it 'saves the mapping the user configured' do
        expect do
          post "#{base_url}/object_mappings", params: mapping_params
        end.to change(Apps::Salesforce::ObjectMapping, :count).by(1)

        expect(Apps::Salesforce::ObjectMapping.first).to have_attributes(
          salesforce_object: 'Account', woofed_model: 'Company', enabled: true
        )
        expect(Apps::Salesforce::ObjectMapping.first.field_mappings).to eq(
          [{ 'salesforce_field' => 'Name', 'woofed_field' => 'name', 'kind' => 'attribute' },
           { 'salesforce_field' => 'Industria__c', 'woofed_field' => 'industria', 'kind' => 'custom_attribute' }]
        )
        expect(response).to redirect_to(base_url)
      end
    end

    context 'when the object is already mapped' do
      let!(:salesforce) { create(:apps_salesforces, :connected) }

      it 'edits it instead of failing on the unique index' do
        create(:apps_salesforce_object_mappings, :disabled, app: salesforce, salesforce_object: 'Account')

        expect do
          post "#{base_url}/object_mappings", params: mapping_params
        end.not_to change(Apps::Salesforce::ObjectMapping, :count)

        expect(Apps::Salesforce::ObjectMapping.first).to be_enabled
      end
    end

    # Only Deal needs these, and the card only sends them for Deal.
    context 'when the mapping carries deal settings' do
      let!(:salesforce) { create(:apps_salesforces, :connected) }
      let(:deal_params) do
        mapping_params.deep_merge(
          object_mapping: {
            salesforce_object: 'Customer_Success__c',
            woofed_model: 'Deal',
            options: { stage_field: 'Status__c', company_field: 'School__c', contact_field: '',
                       create_placeholder_contact: 'false' }
          }
        )
      end

      # "false" is truthy in ruby, and the loader reads the value plainly, so an
      # uncast checkbox would silently turn the placeholder contact on.
      it 'stores the fields it named and the checkbox as a real boolean' do
        post "#{base_url}/object_mappings", params: deal_params

        expect(Apps::Salesforce::ObjectMapping.first.options).to eq(
          'stage_field' => 'Status__c', 'company_field' => 'School__c', 'contact_field' => '',
          'create_placeholder_contact' => false
        )
      end

      # Blank means "not configured", and each part falls back on its own terms:
      # the standard salesforce names for stage and company, nothing at all for
      # the contact, which has no standard lookup to fall back to.
      it 'reads the standard names back for whatever was left blank' do
        post "#{base_url}/object_mappings", params: deal_params

        expect(Apps::Salesforce::ObjectMapping.first).to have_attributes(
          stage_field: 'Status__c', company_field: 'School__c', contact_field: nil
        )
      end

      it 'keeps the options the screen does not carry, instead of replacing the column' do
        create(:apps_salesforce_object_mappings, app: salesforce, salesforce_object: 'Customer_Success__c',
                                                 woofed_model: 'Deal',
                                                 options: { 'stage_map' => { 'Closed Won' => 7 } })

        post "#{base_url}/object_mappings", params: deal_params

        expect(Apps::Salesforce::ObjectMapping.first.options).to include(
          'stage_map' => { 'Closed Won' => 7 }, 'stage_field' => 'Status__c'
        )
      end
    end

    context 'when the mapping is for a model with no settings of its own' do
      let!(:salesforce) { create(:apps_salesforces, :connected) }

      it 'leaves the options empty rather than writing deal settings onto it' do
        post "#{base_url}/object_mappings", params: mapping_params

        expect(Apps::Salesforce::ObjectMapping.first.options).to eq({})
      end
    end

    context 'when the target model is not one the sync can write to' do
      let!(:salesforce) { create(:apps_salesforces, :connected) }

      it 'redirects back with the reason' do
        post "#{base_url}/object_mappings",
             params: mapping_params.deep_merge(object_mapping: { woofed_model: 'User' })

        expect(Apps::Salesforce::ObjectMapping.count).to eq(0)
        expect(flash[:alert]).to include('is not included in the list')
      end
    end

    context 'when no org is connected' do
      it 'asks the user to connect first' do
        post "#{base_url}/object_mappings", params: mapping_params

        expect(Apps::Salesforce::ObjectMapping.count).to eq(0)
        expect(flash[:alert]).to eq(I18n.t('apps.salesforce.missing_connection'))
      end
    end
  end
end
