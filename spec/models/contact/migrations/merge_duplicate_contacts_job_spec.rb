require 'rails_helper'

RSpec.describe Contact::Migrations::MergeDuplicateContactsJob, type: :job do
  skip '#perform' do
    let!(:account) { create(:account) }
    let!(:contact1) { create(:contact, email: 'test@example.com', phone: '123456789') }
    let!(:contact2) { create(:contact, email: 'test@example.com', phone: '987654321') }
    let!(:contact3) { create(:contact, email: 'other@example.com', phone: '123456789') }
    let!(:contact4) { create(:contact, email: '', phone: '') }

    around(:each) do |example|
      orig_value = ENV['GOOD_JOB_EXECUTION_MODE']
      ENV['GOOD_JOB_EXECUTION_MODE'] = 'external'
      example.run
    ensure
      ENV['GOOD_JOB_EXECUTION_MODE'] = orig_value
    end

    context 'merges contacts with duplicate emails and phones' do
      it do
        expect(Contact::Merge).to receive(:new).with(base_contact: contact1, mergee_contact: contact2).and_call_original
        expect(Contact::Merge).to receive(:new).with(base_contact: contact1, mergee_contact: contact3).and_call_original

        expect { described_class.perform_now }
          .to change { Contact.exists?(contact2.id) }.from(true).to(false)
          .and change { Contact.exists?(contact3.id) }.from(true).to(false)
        expect(Contact.exists?(contact1.id)).to be true
        expect(Contact.exists?(contact4.id)).to be true
        expect(contact1.reload.email).to eq('test@example.com')
      end

      it do
        Contact.destroy_all
        contact5 = create(:contact, email: 'contato@woofedcrm.com', phone: '')
        contact6 = create(:contact, email: 'contato@woofedcrm.com', phone: '5511333333')
        contact7 = create(:contact, email: '', phone: '5511333333')

        expect(Contact::Merge).to receive(:new).with(base_contact: contact6, mergee_contact: contact7).and_call_original
        expect(Contact::Merge).to receive(:new).with(base_contact: contact5, mergee_contact: contact6).and_call_original
        expect { described_class.perform_now }
          .to change { Contact.exists?(contact6.id) }.from(true).to(false)
          .and change { Contact.exists?(contact7.id) }.from(true).to(false)
        expect(Contact.exists?(contact5.id)).to be true
        expect(contact5.reload.email).to eq('contato@woofedcrm.com')
        expect(contact5.phone).to eq('+5511333333')
      end
    end

    context 'edge cases' do
      it 'does not merge when there are no duplicates' do
        Contact.destroy_all
        create(:contact, email: 'unique@example.com', phone: '555666777')
        create(:contact, email: 'unique2@example.com', phone: '111111111')
        expect(Contact::Merge).not_to receive(:new)
        expect { described_class.perform_now }
          .to change(Contact, :count).by(0)
      end

      it 'ignores contacts with blank email and phone' do
        Contact.destroy_all
        create(:contact, email: '', phone: '')
        expect(Contact::Merge).not_to receive(:new)
        expect { described_class.perform_now }
          .to change(Contact, :count).by(0)
      end
    end

    context 'error handling' do
      it 'handles errors during merge gracefully' do
        allow_any_instance_of(Contact::Merge).to receive(:perform).and_raise(StandardError, 'Merge failed')
        expect { described_class.perform_now }.to raise_error
      end
    end
  end
end
