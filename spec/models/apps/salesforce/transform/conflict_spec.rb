# spec/models/apps/salesforce/transform/conflict_spec.rb
require 'rails_helper'

RSpec.describe Apps::Salesforce::Transform::Conflict do
  # Creating a contact fires the Chatwoot export callback, which reads
  # Current.account -- the very side effect the import guard has to gate.
  let!(:account) { create(:account) }

  describe '.call' do
    context 'when nothing in woofed owns the values yet' do
      it 'reports no conflict' do
        expect(described_class.call('Contact', { 'email' => 'ana@acme.com' })).to eq(ok: nil)
      end
    end

    context 'when another record already owns the email' do
      it 'names the record that owns it, so a human can resolve the collision' do
        owner = create(:contact, email: 'contato@acme.com')

        result = described_class.call('Contact', { 'email' => 'contato@acme.com' })

        expect(result[:conflict]).to eq(
          I18n.t('apps.salesforce.conflicts.already_taken', field: 'email', value: 'contato@acme.com',
                                                            model: Contact.model_name.human, id: owner.id)
        )
      end

      it 'matches regardless of case, the way the unique index does' do
        create(:contact, email: 'contato@acme.com')

        expect(described_class.call('Contact', { 'email' => 'CONTATO@ACME.COM' })[:conflict]).to be_present
      end
    end

    context 'when another record already owns the phone' do
      it 'reports it' do
        create(:contact, phone: '+551133334444')

        expect(described_class.call('Contact', { 'phone' => '+551133334444' })[:conflict]).to be_present
      end
    end

    context 'when the record that owns the value is the one being updated' do
      it 'reports no conflict, since that is the record this row maps to' do
        contact = create(:contact, email: 'contato@acme.com')

        expect(described_class.call('Contact', { 'email' => 'contato@acme.com' }, recordable: contact))
          .to eq(ok: nil)
      end
    end

    context 'when the values are blank' do
      it 'reports no conflict, since salesforce leaves them empty all the time' do
        create(:contact, email: 'contato@acme.com')

        expect(described_class.call('Contact', { 'email' => '', 'phone' => nil })).to eq(ok: nil)
      end
    end

    context 'when the target model has no such unique field' do
      it 'reports no conflict' do
        expect(described_class.call('Event', { 'email' => 'contato@acme.com' })).to eq(ok: nil)
      end
    end

    context 'when the model is not one the sync writes to' do
      it 'reports no conflict rather than failing' do
        expect(described_class.call('User', { 'email' => 'contato@acme.com' })).to eq(ok: nil)
      end
    end
  end
end
