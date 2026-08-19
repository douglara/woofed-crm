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

    # The de-para most orgs need: naming the two stages alike is the whole
    # configuration.
    context 'when a woofed stage is named like the salesforce one' do
      let!(:negotiation) { create(:stage, pipeline: pipeline, name: 'Negotiation') }
      let(:object_mapping) { create(:apps_salesforce_object_mappings, :opportunity, app: salesforce) }

      it 'lands on it without any mapping, ignoring case and surrounding space' do
        deal = Deal.new(name: 'Contrato anual Acme')

        result = described_class.call(deal, stage_row('StageName' => '  negotiation '), object_mapping)

        expect(result[:ok]).to eq(deal)
        expect(deal).to have_attributes(stage: negotiation, pipeline: pipeline)
      end

      it 'still lets an explicit stage_map override the coincidence of naming' do
        object_mapping.update!(options: { 'stage_map' => { 'Negotiation' => stage.id } })
        deal = Deal.new(name: 'Contrato anual Acme')

        described_class.call(deal, stage_row('StageName' => 'Negotiation'), object_mapping)

        expect(deal.stage).to eq(stage)
      end

      # Nothing stops two pipelines from using the same stage name, and a record
      # that moved pipelines between syncs would be worse than one on either.
      it 'resolves the same pipeline every run when the name lives in two' do
        earlier = create(:stage, pipeline: create(:pipeline, name: 'Alpha outbound'), name: 'Negotiation')
        deal = Deal.new(name: 'Contrato anual Acme')

        described_class.call(deal, stage_row('StageName' => 'Negotiation'), object_mapping)

        expect(deal.stage).to eq(earlier)
      end
    end

    # A custom object mapped onto Deal carries whatever the customer named the
    # field, so StageName is only the default.
    context 'when the mapping reads the stage from another field' do
      let(:object_mapping) do
        create(:apps_salesforce_object_mappings, :opportunity, app: salesforce,
                                                 salesforce_object: 'Customer_Success__c',
                                                 options: { 'stage_field' => 'Status__c' })
      end

      it 'takes the stage from that field and matches it by name' do
        create(:stage, pipeline: pipeline, name: 'Onboarding')
        deal = Deal.new(name: 'Contrato anual Acme')

        result = described_class.call(deal, stage_row('Status__c' => 'Onboarding'), object_mapping)

        expect(result[:ok]).to eq(deal)
        expect(deal.stage.name).to eq('Onboarding')
      end

      it 'names the field when the record carries no stage in it, rather than reporting an empty name' do
        deal = Deal.new(name: 'Contrato anual Acme')

        result = described_class.call(deal, stage_row, object_mapping)

        expect(result[:skip]).to eq(I18n.t('apps.salesforce.load.stage_field_empty', field: 'Status__c'))
      end
    end

    context 'when the salesforce stage is not mapped' do
      it 'reports it rather than putting the deal on an arbitrary stage' do
        deal = Deal.new(name: 'Contrato anual Acme')

        result = described_class.call(deal, stage_row('StageName' => 'Negotiation'), object_mapping)

        expect(result[:skip]).to eq(I18n.t('apps.salesforce.load.stage_not_mapped', stage: 'Negotiation'))
      end

      it 'falls back to the stage the user chose for unmapped names' do
        object_mapping.update!(options: { 'default_stage_id' => stage.id })
        deal = Deal.new(name: 'Contrato anual Acme')

        result = described_class.call(deal, stage_row('StageName' => 'Negotiation'), object_mapping)

        expect(result[:ok]).to eq(deal)
        expect(deal.stage).to eq(stage)
      end
    end

    # A custom object names its own lookups, so the standard AccountId is only a
    # default -- the whole reason a Customer_Success__c row could not find its
    # company.
    context 'when the company is behind a lookup of the object own name' do
      let(:object_mapping) do
        create(:apps_salesforce_object_mappings, :opportunity, app: salesforce,
                                                 salesforce_object: 'Customer_Success__c',
                                                 options: { 'company_field' => 'School__c' })
      end
      let(:payload) do
        { 'Id' => 'a02Hn00000RsTuVIAX', 'Name' => 'CS-0001', 'School__c' => '001Hn00001AbCdEIAV',
          'StageName' => 'Stage 1' }
      end

      it 'links the deal to it and hangs the deal on one of its contacts' do
        deal = Deal.new(name: 'Yearly contract')

        result = described_class.call(deal, stage_row, object_mapping)
        deal.save!

        expect(result[:ok]).to eq(deal)
        expect(deal.contact).to eq(contact)
        expect(deal.reload.companies).to eq([company])
      end

      it 'reports it when the lookup points at a record woofed has not imported' do
        deal = Deal.new(name: 'Yearly contract')

        result = described_class.call(deal, stage_row('School__c' => '001Hn00009ZzZzZIAV'), object_mapping)

        expect(result[:skip]).to eq(I18n.t('apps.salesforce.load.contact_not_found'))
      end
    end

    # Objects identify a person in whichever way their org modelled it, so the
    # named field is tried as an id, then an email, then a phone.
    context 'when the contact field is not a lookup' do
      let!(:by_email) { create(:contact, full_name: 'Carla', email: 'carla@acme.com') }
      let!(:by_phone) { create(:contact, full_name: 'Diego', phone: '+5511999990000') }
      let(:object_mapping) do
        create(:apps_salesforce_object_mappings, :opportunity, app: salesforce,
                                                 options: { 'contact_field' => 'Contact_Info__c' })
      end

      it 'finds the person by email, whatever the case it was stored in' do
        deal = Deal.new(name: 'Yearly contract')
        row = stage_row('StageName' => 'Stage 1', 'Contact_Info__c' => 'CARLA@acme.com')

        described_class.call(deal, row, object_mapping)

        expect(deal.contact).to eq(by_email)
      end

      it 'falls back to the phone when the value is not an email' do
        deal = Deal.new(name: 'Yearly contract')
        row = stage_row('StageName' => 'Stage 1', 'Contact_Info__c' => '+5511999990000')

        described_class.call(deal, row, object_mapping)

        expect(deal.contact).to eq(by_phone)
      end

      it 'goes on to the company when the value matches nobody' do
        deal = Deal.new(name: 'Yearly contract')
        row = stage_row('StageName' => 'Stage 1', 'Contact_Info__c' => 'nobody@acme.com')

        described_class.call(deal, row, object_mapping)

        expect(deal.contact).to eq(contact)
      end
    end

    # Only an org that built one has it; an Opportunity has no such lookup.
    context 'when the object points straight at a contact' do
      let!(:direct) { create(:contact, full_name: 'Bruno') }
      let!(:contact_mapping) do
        create(:apps_salesforce_record_mappings, app: salesforce, recordable: direct,
                                                 salesforce_object: 'Contact',
                                                 salesforce_id: '003Hn00002QwErTIAX')
      end
      let(:object_mapping) do
        create(:apps_salesforce_object_mappings, :opportunity, app: salesforce,
                                                 options: { 'contact_field' => 'Contact__c' })
      end

      it 'uses that person rather than whoever happens to be on the company' do
        deal = Deal.new(name: 'Yearly contract')
        row = stage_row('StageName' => 'Stage 1', 'Contact__c' => '003Hn00002QwErTIAX')

        described_class.call(deal, row, object_mapping)

        expect(deal.contact).to eq(direct)
      end

      it 'falls back to a contact of the company when the lookup is empty' do
        deal = Deal.new(name: 'Yearly contract')

        described_class.call(deal, stage_row('StageName' => 'Stage 1', 'Contact__c' => nil), object_mapping)

        expect(deal.contact).to eq(contact)
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
