# spec/models/apps/salesforce/load/record/find_or_build_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Load::Record::FindOrBuild do
  let!(:account) { create(:account) }
  let!(:salesforce) { create(:apps_salesforces) }
  let!(:object_mapping) { create(:apps_salesforce_object_mappings, app: salesforce) }
  let!(:sync_record) { create(:apps_salesforce_sync_records, app: salesforce) }

  describe '#call' do
    context 'when the salesforce record was imported before' do
      it 'returns the woofed record it owns, so the row updates instead of duplicating' do
        company = create(:company, name: 'Acme Ltda')
        mapping = create(:apps_salesforce_record_mappings, app: salesforce, recordable: company,
                                                           salesforce_id: sync_record.salesforce_id)

        result = described_class.new(sync_record, object_mapping, { 'name' => 'Acme' }).call

        expect(result[:ok]).to eq(company)
        expect(result[:mapping]).to eq(mapping)
      end
    end

    context 'when nobody mapped the record but the crm already knows the email' do
      it 'adopts the existing record rather than failing on the unique index' do
        company = create(:company, email: 'contato@acme.com')

        result = described_class.new(sync_record, object_mapping, { 'email' => 'contato@acme.com' }).call

        expect(result[:ok]).to eq(company)
        expect(result[:mapping]).to be_nil
      end

      it 'matches regardless of case, the way the unique index does' do
        company = create(:company, email: 'contato@acme.com')

        result = described_class.new(sync_record, object_mapping, { 'email' => 'CONTATO@ACME.COM' }).call

        expect(result[:ok]).to eq(company)
      end

      it 'falls back to the phone when there is no email to match on' do
        company = create(:company, phone: '+551133334444')

        result = described_class.new(sync_record, object_mapping, { 'phone' => '+551133334444' }).call

        expect(result[:ok]).to eq(company)
      end

      it 'prefers the email match, since a phone may be a shared switchboard' do
        by_email = create(:company, email: 'contato@acme.com')
        create(:company, phone: '+551133334444')

        result = described_class.new(sync_record, object_mapping,
                                     { 'email' => 'contato@acme.com', 'phone' => '+551133334444' }).call

        expect(result[:ok]).to eq(by_email)
      end
    end

    context 'when the crm has never seen this record' do
      it 'builds a new one' do
        result = described_class.new(sync_record, object_mapping, { 'name' => 'Acme' }).call

        expect(result[:ok]).to be_a(Company)
        expect(result[:ok]).to be_new_record
      end

      it 'builds a new one when the matchable values are blank' do
        create(:company, email: 'contato@acme.com')

        result = described_class.new(sync_record, object_mapping, { 'email' => '', 'phone' => nil }).call

        expect(result[:ok]).to be_new_record
      end
    end

    context 'when the target model has no such matchable field' do
      it 'builds a new record instead of failing' do
        mapping = create(:apps_salesforce_object_mappings, app: salesforce, salesforce_object: 'Task',
                                                           woofed_model: 'Event')

        result = described_class.new(sync_record, mapping, { 'email' => 'contato@acme.com' }).call

        expect(result[:ok]).to be_a(Event)
        expect(result[:ok]).to be_new_record
      end
    end
  end
end
