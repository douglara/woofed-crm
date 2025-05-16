require 'rails_helper'

RSpec.describe Contact::Migrations::MergeDuplicateContacts do
  describe '#call' do
    let!(:account) { create(:account) }
    let!(:contact1) { create(:contact, email: 'test@example.com', phone: '123456789') }
    let!(:contact2) { create(:contact, email: 'test@example.com', phone: '987654321') }
    let!(:contact3) { create(:contact, email: 'other@example.com', phone: '123456789') }
    let!(:contact4) { create(:contact, email: '', phone: '') }

    context 'with enqueue: false (synchronous)' do
      let(:subject) { described_class.new(enqueue: false) }

      context 'merges contacts with duplicate emails and phone synchronously' do
        it do
          expect(Contact::Merge).to receive(:new).with(base_contact: contact1, mergee_contact: contact2).and_call_original
          expect(Contact::Merge).to receive(:new).with(base_contact: contact1, mergee_contact: contact3).and_call_original
          expect { subject.call }
            .to change { Contact.exists?(contact2.id) }.from(true).to(false)
            .and change { Contact.exists?(contact3.id) }.from(true).to(false)
          expect(Contact.exists?(contact1.id)).to be true
          expect(Contact.exists?(contact4.id)).to be true
          expect(contact1.reload.email).to eq('test@example.com')
          expect(contact1.phone).to eq('+123456789')
        end
        it do
          Contact.destroy_all
          contact5 = create(:contact, email: 'contato@woofedcrm.com', phone: '')
          contact6 = create(:contact, email: 'contato@woofedcrm.com', phone: '5511333333')
          contact7 = create(:contact, email: '', phone: '5511333333')

          expect(Contact::Merge).to receive(:new).with(base_contact: contact5, mergee_contact: contact6).and_call_original
          expect(Contact::Merge).to receive(:new).with(base_contact: contact6, mergee_contact: contact7).and_call_original
          # expect(Contact::Merge).to receive(:new).with(base_contact: contact5, mergee_contact: contact7).and_call_original esse é o certo
          expect { subject.call }
            .to change { Contact.exists?(contact6.id) }.from(true).to(false)
            .and change { Contact.exists?(contact7.id) }.from(true).to(false)
          expect(Contact.exists?(contact5.id)).to be true
          expect(contact5.reload.email).to eq('contato@woofedcrm.com')
          expect(contact5.phone).to eq('+5511333333')
        end
      end


      it 'merges contacts with duplicate phones, skipping those already processed by email' do
        Contact.destroy_all
        contact5 = create(:contact, email: 'unique1@example.com', phone: '111222333')
        contact6 = create(:contact, email: 'unique2@example.com', phone: '111222333')

        expect(Contact::Merge).to receive(:new).with(base_contact: contact5, mergee_contact: contact6).and_call_original
        expect { subject.call }
          .to change { Contact.exists?(contact6.id) }.from(true).to(false)
        expect(Contact.exists?(contact5.id)).to be true
      end

      it 'does not merge when there are no duplicates' do
        Contact.destroy_all
        create(:contact, email: 'unique@example.com', phone: '555666777')
        create(:contact, email: 'unique2@example.com', phone: '111111111')
        expect(Contact::Merge).not_to receive(:new)
        expect { subject.call }
          .to change(Contact, :count).by(0)
      end

      it 'ignores contacts with blank email and phone' do
        Contact.destroy_all
        create(:contact, email: '', phone: '')
        expect(Contact::Merge).not_to receive(:new)
        expect { subject.call }
          .to change(Contact, :count).by(0)
      end

      it 'handles errors during merge gracefully' do
        allow_any_instance_of(Contact::Merge).to receive(:perform).and_raise(StandardError, 'Merge failed')
        expect(Rails.logger).to receive(:error).with(/Failed to merge contact/).twice
        expect { subject.call }.not_to raise_error
      end
    end

    context 'with enqueue: true (asynchronous)' do
      let(:subject) { described_class.new(enqueue: true) }

      it 'enqueues jobs for contacts with duplicate emails' do
        expect(Contact::MergeJob).to receive(:set).with(queue: 'migration').and_call_original.twice
        # expect(Contact::MergeJob).to receive(:perform_later).with(contact1.id, contact2.id)
        # expect(Contact::MergeJob).to receive(:perform_later).with(contact1.id, contact3.id)
        subject.call
      end

      it 'enqueues jobs for contacts with duplicate phones, skipping those already processed by email' do
        Contact.destroy_all
        create(:contact, email: 'unique1@example.com', phone: '111222333')
        create(:contact, email: 'unique2@example.com', phone: '111222333')

        expect(Contact::MergeJob).to receive(:set).with(queue: 'migration').and_call_original
        # expect(Contact::MergeJob).to receive(:perform_later).with(contact5.id, contact6.id)
        subject.call
      end
    end
  end
end
