# spec/models/apps/salesforce/load/batch_worker_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Load::BatchWorker do
  let!(:account) { create(:account) }
  let!(:salesforce) { create(:apps_salesforces) }
  let!(:object_mapping) do
    create(:apps_salesforce_object_mappings, app: salesforce, field_mappings: [
             { 'salesforce_field' => 'Name', 'woofed_field' => 'name', 'kind' => 'attribute' }
           ])
  end
  let!(:sync_run) { create(:apps_salesforce_sync_runs, :running, app: salesforce) }

  def stage(payload)
    create(:apps_salesforce_sync_records, app: salesforce, sync_run: sync_run,
                                          salesforce_id: payload['Id'], payload: payload)
  end

  describe '#perform' do
    context 'when rows are waiting' do
      it 'loads each one into woofed' do
        stage('Id' => '001Hn00001AbCdEIAV', 'Name' => 'Acme Ltda')
        stage('Id' => '001Hn00001XyZwVIAX', 'Name' => 'Beta SA')

        described_class.new.perform(sync_run.id)

        expect(Company.pluck(:name)).to contain_exactly('Acme Ltda', 'Beta SA')
        expect(Apps::Salesforce::SyncRecord.pending).to be_empty
      end

      it 'leaves the rows it already loaded alone when it runs again' do
        stage('Id' => '001Hn00001AbCdEIAV', 'Name' => 'Acme Ltda')

        described_class.new.perform(sync_run.id)
        described_class.new.perform(sync_run.id)

        expect(Company.count).to eq(1)
      end
    end

    context 'when a row cannot be loaded' do
      it 'costs one row rather than the batch, and is counted for the sync screen' do
        stage('Id' => '001Hn00001AbCdEIAV', 'Name' => '')
        stage('Id' => '001Hn00001XyZwVIAX', 'Name' => 'Beta SA')

        described_class.new.perform(sync_run.id)

        expect(Company.pluck(:name)).to eq(['Beta SA'])
        expect(sync_run.reload.records_failed).to eq(1)
      end
    end

    context 'when the run no longer exists' do
      it 'does nothing' do
        expect { described_class.new.perform(0) }.not_to raise_error
      end
    end
  end
end
