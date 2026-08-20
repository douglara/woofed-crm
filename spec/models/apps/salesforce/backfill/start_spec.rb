# spec/models/apps/salesforce/backfill/start_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Backfill::Start do
  include_context 'with salesforce backfill jobs enqueued'

  let!(:salesforce) { create(:apps_salesforces, :connected) }

  describe '#call' do
    context 'when objects are enabled' do
      it 'queues one run per enabled object, in dependency order' do
        create(:apps_salesforce_object_mappings, :opportunity, app: salesforce)
        create(:apps_salesforce_object_mappings, app: salesforce, salesforce_object: 'Account')

        result = described_class.new(salesforce).call

        expect(result[:ok].map(&:salesforce_object)).to eq(%w[Account Opportunity])
        expect(salesforce.sync_runs.pluck(:kind).uniq).to eq(['backfill'])
      end

      it 'queues a custom object last, since nothing else depends on it' do
        create(:apps_salesforce_object_mappings, app: salesforce, salesforce_object: 'Contrato__c',
                                                 woofed_model: 'Deal')
        create(:apps_salesforce_object_mappings, app: salesforce, salesforce_object: 'Account')

        result = described_class.new(salesforce).call

        expect(result[:ok].map(&:salesforce_object)).to eq(%w[Account Contrato__c])
      end

      it 'enqueues the download of each run' do
        create(:apps_salesforce_object_mappings, app: salesforce)

        expect { described_class.new(salesforce).call }
          .to have_enqueued_job(Apps::Salesforce::Backfill::ObjectJob)
      end
    end

    context 'when an object is disabled' do
      it 'leaves it out, since nothing syncs until the user turns it on' do
        create(:apps_salesforce_object_mappings, :disabled, app: salesforce)

        result = described_class.new(salesforce).call

        expect(result[:ok]).to be_empty
        expect(salesforce.sync_runs).to be_empty
      end
    end

    context 'when the object is already being downloaded' do
      it 'skips it, so the org never gets a second bulk job for the same data' do
        create(:apps_salesforce_object_mappings, app: salesforce)
        create(:apps_salesforce_sync_runs, :running, app: salesforce, salesforce_object: 'Account')

        result = described_class.new(salesforce).call

        expect(result[:ok]).to be_empty
        expect(salesforce.sync_runs.count).to eq(1)
      end
    end

    context 'when the org was never connected' do
      it 'reports it instead of queueing work that cannot run' do
        create(:apps_salesforce_object_mappings, app: salesforce)
        salesforce.update!(refresh_token: nil)

        expect(described_class.new(salesforce).call[:error])
          .to eq(I18n.t('apps.salesforce.missing_connection'))
      end
    end

    context 'when it is a catch-up rather than the initial load' do
      it 'records the kind, so the query knows to use the cursor' do
        create(:apps_salesforce_object_mappings, app: salesforce)

        result = described_class.new(salesforce, kind: 'delta').call

        expect(result[:ok].first).to be_delta
      end
    end
  end
end
