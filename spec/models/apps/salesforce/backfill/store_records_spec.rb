# spec/models/apps/salesforce/backfill/store_records_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Backfill::StoreRecords do
  let!(:salesforce) { create(:apps_salesforces) }
  let!(:sync_run) { create(:apps_salesforce_sync_runs, :running, app: salesforce) }
  let(:records) do
    [
      { 'Id' => '001Hn00001AbCdEIAV', 'Name' => 'Acme Ltda', 'SystemModstamp' => '2026-08-01T14:22:31.000Z' },
      { 'Id' => '001Hn00001XyZwVIAX', 'Name' => 'Beta SA', 'SystemModstamp' => '2026-08-02T09:10:02.000Z' }
    ]
  end

  describe '#call' do
    context 'when a page arrives' do
      it 'stages the rows exactly as salesforce sent them' do
        expect { described_class.new(sync_run, records).call }
          .to change(Apps::Salesforce::RawRecord, :count).by(2)

        staged = Apps::Salesforce::RawRecord.find_by(salesforce_id: '001Hn00001AbCdEIAV')
        expect(staged).to have_attributes(
          app_id: salesforce.id, sync_run_id: sync_run.id, salesforce_object: 'Account', status: 'pending'
        )
        expect(staged.payload).to eq(records.first)
      end

      it 'counts what it downloaded, which is what the progress panel shows' do
        described_class.new(sync_run, records).call
        described_class.new(sync_run, records).call

        expect(sync_run.reload.records_downloaded).to eq(4)
      end

      it 'leaves the cursor alone, since it was stamped when the query was submitted' do
        submitted_at = sync_run.cursor

        described_class.new(sync_run, records).call

        expect(sync_run.reload.cursor).to be_within(1.second).of(submitted_at)
      end

      it 'normalises the ids so a staged row matches its record link' do
        described_class.new(sync_run, [{ 'Id' => '001Hn00001AbCdE', 'Name' => 'Acme' }]).call

        expect(Apps::Salesforce::RawRecord.first.salesforce_id).to eq('001Hn00001AbCdEIAV')
      end
    end

    context 'when a row carries no id' do
      it 'skips it, since nothing could ever be mapped to it' do
        described_class.new(sync_run, [{ 'Name' => 'No id' }, records.first]).call

        expect(Apps::Salesforce::RawRecord.pluck(:salesforce_id)).to eq(['001Hn00001AbCdEIAV'])
      end
    end

    context 'when the page is empty' do
      it 'writes nothing and reports nothing downloaded' do
        expect(described_class.new(sync_run, []).call).to eq(ok: 0)
        expect(sync_run.reload.records_downloaded).to eq(0)
      end
    end
  end
end
