# spec/models/apps/salesforce/load/events/prepare_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Load::Events::Prepare do
  let!(:account) { create(:account) }
  let!(:salesforce) { create(:apps_salesforces) }
  let!(:contact) { create(:contact, full_name: 'Ana') }
  let(:object_mapping) do
    create(:apps_salesforce_object_mappings, app: salesforce, salesforce_object: 'Task',
                                             woofed_model: 'Event')
  end
  let(:payload) do
    {
      'Id' => '00THn00001AbCdEIAV',
      'Subject' => 'Ligação de follow-up',
      'WhoId' => '003Hn00002XyZwVIAV',
      'IsClosed' => 'false',
      'ActivityDate' => '2026-08-01'
    }
  end

  def stage_task(overrides = {})
    create(:apps_salesforce_sync_records, app: salesforce, salesforce_object: 'Task',
                                          salesforce_id: payload['Id'], payload: payload.merge(overrides))
  end

  def map_contact
    create(:apps_salesforce_record_mappings, app: salesforce, recordable: contact,
                                             salesforce_object: 'Contact',
                                             salesforce_id: '003Hn00002XyZwVIAV')
  end

  describe '.call' do
    context 'when salesforce recorded the person on the activity' do
      it 'belongs it to that contact, as an activity' do
        map_contact
        event = Event.new(title: 'Ligação de follow-up')

        result = described_class.call(event, stage_task, object_mapping)

        expect(result[:ok]).to eq(event)
        expect(event).to have_attributes(contact: contact, kind: 'activity', done_at: nil)
      end

      it 'marks it done with the date salesforce closed it' do
        map_contact
        event = Event.new(title: 'Ligação de follow-up')

        described_class.call(event, stage_task('IsClosed' => 'true'), object_mapping)

        expect(event.done_at).to eq(Time.utc(2026, 8, 1))
      end

      it 'uses the kind the user chose for this object' do
        map_contact
        object_mapping.update!(options: { 'kind' => 'note' })
        event = Event.new(title: 'Ligação de follow-up')

        described_class.call(event, stage_task, object_mapping)

        expect(event.kind).to eq('note')
      end

      it 'ignores a kind woofed does not have' do
        map_contact
        object_mapping.update!(options: { 'kind' => 'telepathy' })
        event = Event.new(title: 'Ligação de follow-up')

        described_class.call(event, stage_task, object_mapping)

        expect(event.kind).to eq('activity')
      end
    end

    context 'when the activity only says which deal it concerns' do
      it 'belongs it to that deal and to the deal contact' do
        pipeline = create(:pipeline, account: account)
        stage = create(:stage, pipeline: pipeline)
        deal = create(:deal, contact: contact, stage: stage, pipeline: pipeline)
        create(:apps_salesforce_record_mappings, app: salesforce, recordable: deal,
                                                 salesforce_object: 'Opportunity',
                                                 salesforce_id: '006Hn00003RsTuVIAV')
        event = Event.new(title: 'Ligação de follow-up')

        described_class.call(event, stage_task('WhoId' => nil, 'WhatId' => '006Hn00003RsTuVIAV'),
                             object_mapping)

        expect(event).to have_attributes(contact: contact, deal: deal)
      end
    end

    context 'when the activity only says which company it concerns' do
      it 'belongs it to a contact of that company' do
        company = create(:company, name: 'Acme Ltda')
        company.contacts << contact
        create(:apps_salesforce_record_mappings, app: salesforce, recordable: company,
                                                 salesforce_object: 'Account',
                                                 salesforce_id: '001Hn00001AbCdEIAV')
        event = Event.new(title: 'Ligação de follow-up')

        described_class.call(event, stage_task('WhoId' => nil, 'WhatId' => '001Hn00001AbCdEIAV'),
                             object_mapping)

        expect(event.contact).to eq(contact)
      end
    end

    context 'when there is nobody the activity could belong to' do
      it 'reports it instead of importing an orphan' do
        event = Event.new(title: 'Ligação de follow-up')

        result = described_class.call(event, stage_task('WhoId' => nil), object_mapping)

        expect(result[:skip]).to eq(I18n.t('apps.salesforce.load.event_contact_not_found'))
      end
    end
  end
end
