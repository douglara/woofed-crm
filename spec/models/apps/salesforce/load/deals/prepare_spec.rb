# spec/models/apps/salesforce/load/deals/prepare_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Load::Deals::Prepare do
  let!(:account) { create(:account) }
  let!(:salesforce) { create(:apps_salesforces) }
  let!(:pipeline) { create(:pipeline, account: account) }
  let!(:stage) { create(:stage, pipeline: pipeline) }
  let!(:company) { create(:company, name: 'Acme Ltda') }
  let!(:contact) { create(:contact, full_name: 'Ana') }
  let!(:account_mapping) do
    create(:apps_salesforce_record_mappings, app: salesforce, recordable: company,
                                             salesforce_object: 'Account',
                                             salesforce_id: '001Hn00001AbCdEIAV')
  end
  let(:payload) do
    {
      'Id' => '006Hn00003RsTuVIAX',
      'Name' => 'Contrato anual Acme',
      'AccountId' => '001Hn00001AbCdEIAV',
      'StageName' => 'Prospecting',
      'IsClosed' => 'false',
      'IsWon' => 'false',
      'CloseDate' => '2026-09-30'
    }
  end
  let(:object_mapping) do
    create(:apps_salesforce_object_mappings, :opportunity, app: salesforce,
                                             options: { 'stage_map' => { 'Prospecting' => stage.id } })
  end

  def stage_row(overrides = {})
    create(:apps_salesforce_sync_records, app: salesforce, salesforce_object: 'Opportunity',
                                          salesforce_id: payload['Id'], payload: payload.merge(overrides))
  end

  before { company.contacts << contact }

  describe '.call' do
    context 'when the stage is mapped and the company has a contact' do
      it 'places the deal on that stage, its pipeline and that contact' do
        deal = Deal.new(name: 'Contrato anual Acme')

        result = described_class.call(deal, stage_row, object_mapping)

        expect(result[:ok]).to eq(deal)
        expect(deal).to have_attributes(stage: stage, pipeline: pipeline, contact: contact, status: 'open')
      end

      it 'links the deal to the company salesforce says it is with' do
        deal = Deal.new(name: 'Contrato anual Acme')

        described_class.call(deal, stage_row, object_mapping)
        deal.save!

        expect(deal.reload.companies).to eq([company])
      end

      it 'does not pile up the link when the row is loaded again' do
        deal = create(:deal, contact: contact, stage: stage, pipeline: pipeline, companies: [company])

        described_class.call(deal, stage_row, object_mapping)
        deal.save!

        expect(deal.reload.companies).to eq([company])
      end
    end

    context 'when the opportunity is closed' do
      it 'marks a won deal with the date salesforce closed it' do
        deal = Deal.new(name: 'Contrato anual Acme')

        described_class.call(deal, stage_row('IsClosed' => 'true', 'IsWon' => 'true'), object_mapping)

        expect(deal.status).to eq('won')
        expect(deal.won_at).to eq(Time.utc(2026, 9, 30))
      end

      it 'marks a lost deal the same way' do
        deal = Deal.new(name: 'Contrato anual Acme')

        described_class.call(deal, stage_row('IsClosed' => 'true', 'IsWon' => 'false'), object_mapping)

        expect(deal.status).to eq('lost')
        expect(deal.lost_at).to eq(Time.utc(2026, 9, 30))
      end
    end

    context 'when the salesforce stage is not mapped' do
      it 'reports it rather than putting the deal on an arbitrary stage' do
        deal = Deal.new(name: 'Contrato anual Acme')

        result = described_class.call(deal, stage_row('StageName' => 'Negociação'), object_mapping)

        expect(result[:skip]).to eq(I18n.t('apps.salesforce.load.stage_not_mapped', stage: 'Negociação'))
      end

      it 'falls back to the stage the user chose for unmapped names' do
        object_mapping.update!(options: { 'default_stage_id' => stage.id })
        deal = Deal.new(name: 'Contrato anual Acme')

        result = described_class.call(deal, stage_row('StageName' => 'Negociação'), object_mapping)

        expect(result[:ok]).to eq(deal)
        expect(deal.stage).to eq(stage)
      end
    end

    context 'when there is nobody to hang the deal on' do
      before { company.contacts.destroy_all }

      it 'reports it instead of inventing a contact' do
        deal = Deal.new(name: 'Contrato anual Acme')

        result = described_class.call(deal, stage_row, object_mapping)

        expect(result[:skip]).to eq(I18n.t('apps.salesforce.load.contact_not_found'))
        expect(Contact.where(full_name: 'Acme Ltda')).to be_empty
      end

      it 'creates a contact named after the company when the user asked for it' do
        object_mapping.update!(options: object_mapping.options.merge('create_placeholder_contact' => true))
        deal = Deal.new(name: 'Contrato anual Acme')

        described_class.call(deal, stage_row, object_mapping)

        expect(deal.contact.full_name).to eq('Acme Ltda')
      end
    end

    context 'when the opportunity has no account in woofed yet' do
      it 'reports it, since the accounts are imported before the opportunities' do
        deal = Deal.new(name: 'Contrato anual Acme')

        result = described_class.call(deal, stage_row('AccountId' => nil), object_mapping)

        expect(result[:skip]).to eq(I18n.t('apps.salesforce.load.contact_not_found'))
      end
    end
  end
end
