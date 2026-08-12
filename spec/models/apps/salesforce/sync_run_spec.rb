# == Schema Information
#
# Table name: apps_salesforce_sync_runs
#
#  id                 :bigint           not null, primary key
#  cursor             :datetime
#  error              :text
#  finished_at        :datetime
#  kind               :string           default("backfill"), not null
#  locator            :string
#  records_downloaded :bigint           default(0), not null
#  records_failed     :bigint           default(0), not null
#  salesforce_object  :string           not null
#  started_at         :datetime
#  status             :string           default("pending"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  app_id             :bigint           not null
#  bulk_job_id        :string
#
# Indexes
#
#  index_apps_salesforce_sync_runs_on_app_id            (app_id)
#  index_salesforce_sync_runs_on_app_object_and_status  (app_id,salesforce_object,status)
#
# Foreign Keys
#
#  fk_rails_...  (app_id => apps_salesforces.id)
#
# spec/models/apps/salesforce/sync_run_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::SyncRun do
  let!(:salesforce) { create(:apps_salesforces) }

  describe 'validations' do
    context 'validates salesforce_object' do
      context 'valid' do
        it do
          run = build(:apps_salesforce_sync_runs, app: salesforce)

          expect(run).to be_valid
        end
      end
      context 'invalid' do
        it 'when salesforce_object is blank' do
          run = build(:apps_salesforce_sync_runs, app: salesforce, salesforce_object: '')

          expect(run).to be_invalid
          expect(run.errors[:salesforce_object]).to include("can't be blank")
        end
      end
    end
  end

  describe 'resumption state' do
    it 'keeps the bulk job id and the locator, so a retry never creates a second job' do
      run = create(:apps_salesforce_sync_runs, :running, app: salesforce)

      run.update!(locator: 'MTAwMDA', records_downloaded: 10_000)

      expect(run.reload).to have_attributes(bulk_job_id: '750Hn00000AbCdEIAV', locator: 'MTAwMDA',
                                            records_downloaded: 10_000)
    end
  end

  describe '#start!' do
    it 'marks the run as running and stamps when it began' do
      run = create(:apps_salesforce_sync_runs, app: salesforce)

      run.start!

      expect(run.reload).to be_running
      expect(run.started_at).to be_present
    end
  end

  describe '#complete!' do
    it 'advances the cursor the next delta starts from' do
      run = create(:apps_salesforce_sync_runs, :running, app: salesforce)
      high_water_mark = Time.zone.parse('2026-08-01 14:22:31 UTC')

      run.complete!(cursor: high_water_mark)

      expect(run.reload).to be_completed
      expect(run).to have_attributes(cursor: high_water_mark, finished_at: be_present)
    end

    it 'keeps the previous cursor when the run had nothing newer to report' do
      run = create(:apps_salesforce_sync_runs, :delta, :running, app: salesforce)
      previous_cursor = run.cursor

      run.complete!

      expect(run.reload.cursor).to be_within(1.second).of(previous_cursor)
    end
  end

  describe '#fail!' do
    it 'records why it stopped instead of leaving the run hanging' do
      run = create(:apps_salesforce_sync_runs, :running, app: salesforce)

      run.fail!('Bulk job aborted')

      expect(run.reload).to be_failed
      expect(run).to have_attributes(error: 'Bulk job aborted', finished_at: be_present)
      expect(described_class.unfinished).to be_empty
    end
  end
end
