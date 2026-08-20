require 'rails_helper'

RSpec.describe Inertia::Accounts::Apps::Salesforces::RawRecordsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:salesforce) { create(:apps_salesforces, :connected) }
  let!(:object_mapping) do
    create(:apps_salesforce_object_mappings, app: salesforce, field_mappings: [
             { 'salesforce_field' => 'Name', 'woofed_field' => 'name', 'kind' => 'attribute' }
           ])
  end
  let(:base_url) { "/accounts/#{account.id}/apps/salesforce" }

  before { sign_in(user) }

  describe 'POST /accounts/{account.id}/apps/salesforce/raw_records/{id}/retry' do
    context 'when the reason it failed is gone' do
      it 'imports the row from the payload it kept' do
        raw_record = create(:apps_salesforce_raw_records, app: salesforce, status: 'failed',
                                                          error: "Name can't be blank",
                                                          payload: { 'Id' => '001Hn00001AbCdEIAV',
                                                                     'Name' => 'Acme Ltda' })

        post "#{base_url}/raw_records/#{raw_record.id}/retry"

        expect(raw_record.reload).to be_processed
        expect(Company.find_by(name: 'Acme Ltda')).to be_present
        expect(flash[:notice]).to eq(I18n.t('apps.salesforce.raw_records.processed'))
      end
    end

    context 'when it fails again' do
      it 'says so and keeps the new reason on the row' do
        raw_record = create(:apps_salesforce_raw_records, app: salesforce, status: 'failed',
                                                          payload: { 'Id' => '001Hn00001AbCdEIAV',
                                                                     'Name' => '' })

        post "#{base_url}/raw_records/#{raw_record.id}/retry"

        expect(raw_record.reload).to be_failed
        expect(raw_record.error).to include("Name can't be blank")
        expect(flash[:notice]).to eq(I18n.t('apps.salesforce.raw_records.failed'))
      end
    end

    context 'when the row is gone' do
      it 'says so instead of failing' do
        post "#{base_url}/raw_records/0/retry"

        expect(flash[:alert]).to eq(I18n.t('apps.salesforce.raw_records.not_found'))
      end
    end
  end
end
