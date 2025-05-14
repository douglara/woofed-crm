require 'rails_helper'

RSpec.describe Contact::Merge do
  let!(:account) { create(:account) }
  let(:base_contact) { create(:contact) }
  let(:mergee_contact) { create(:contact) }
  let(:merge_service) { described_class.new(base_contact:, mergee_contact:) }

  describe '#perform' do
    context 'when contacts are the same' do
      let(:mergee_contact) { base_contact }

      it 'raises an error' do
        expect { merge_service.perform }.to raise_error(StandardError, 'contact does merge with same contact')
      end
    end

    context 'when contacts are different' do
      let!(:base_contact_deal) { create(:deal, contact: base_contact, name: 'deal base contact name test') }
      let!(:base_contact_event) { create(:event, contact: base_contact, title: 'event base contact title test') }
      let!(:mergee_contact_deal) { create(:deal, contact: mergee_contact, name: 'deal merge contact name test') }
      let!(:mergee_contact_event) { create(:event, contact: mergee_contact, title: 'event merge contact title test') }

      it 'merges deals and event to base contact' do
        expect { merge_service.perform }
          .to change { mergee_contact_deal.reload.contact_id }
          .from(mergee_contact.id).to(base_contact.id)
          .and change { mergee_contact_event.reload.contact_id }
          .from(mergee_contact.id).to(base_contact.id)
      end

      it 'destroys mergee contact' do
        expect { merge_service.perform }
          .to change(Contact, :count).by(-1)
          .and change { Contact.exists?(mergee_contact.id) }
          .from(true).to(false)
      end

      it 'updates base contact with merged attributes' do
        base_contact.update(full_name: 'Base Name', email: 'base@example.com', phone: '+5522998878456', additional_attributes: { field1: 'value1' })
        mergee_contact.update(full_name:  'Merge Name', email: 'mergee@example.com', phone: '+5522998878456' , additional_attributes: { field2: 'value2' })

        merge_service.perform
        base_contact.reload

        expect(base_contact.full_name).to eq('Base Name')
        expect(base_contact.email).to eq('base@example.com')
        expect(base_contact.additional_attributes).to eq('field1' => 'value1', 'field2' => 'value2')
      end

      it 'performs operations within a transaction' do
        allow(base_contact).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

        expect { merge_service.perform }.to raise_error(ActiveRecord::RecordInvalid)

        expect(Contact.exists?(mergee_contact.id)).to be_truthy
        expect(Deal.where(contact_id: base_contact.id).count).to eq(1)
      end
    end
  end

  describe '#validate_contacts' do
    context 'when contacts are the same' do
      let(:mergee_contact) { base_contact }

      it 'raises an error' do
        expect { merge_service.send(:validate_contacts) }
          .to raise_error(StandardError, 'contact does merge with same contact')
      end
    end

    context 'when contacts are different' do
      it 'does not raise an error' do
        expect { merge_service.send(:validate_contacts) }.not_to raise_error
      end
    end
  end

  describe '#merge_deals' do
    let!(:deal) { create(:deal, contact: mergee_contact) }
    let!(:deal2) { create(:deal, contact: mergee_contact) }
    let!(:deal3) { create(:deal, contact: base_contact) }

    it 'updates deals contact_id to base_contact' do
      merge_service.send(:merge_deals)
      expect(deal.reload.contact_id).to eq(base_contact.id)
      expect(deal2.reload.contact_id).to eq(base_contact.id)
      expect(deal3.reload.contact_id).to eq(base_contact.id)
    end
  end

  describe '#merge_events' do
    let!(:event) { create(:event, contact: mergee_contact) }
    let!(:event2) { create(:event, contact: mergee_contact) }
    let!(:event3) { create(:event, contact: base_contact) }

    it 'updates event sender to base_contact' do
      merge_service.send(:merge_events)
      expect(event.reload.contact_id).to eq(base_contact.id)
      expect(event2.reload.contact_id).to eq(base_contact.id)
      expect(event3.reload.contact_id).to eq(base_contact.id)
    end
  end

  describe '#merge_and_remove_mergee_contact' do
    before do
      base_contact.update(full_name: 'Base Name', additional_attributes: { field1: 'value1' })
      mergee_contact.update(full_name: 'Mergee Name', additional_attributes: { field2: 'value2' })
    end

    it 'destroys mergee_contact' do
      expect { merge_service.send(:merge_and_remove_mergee_contact) }
        .to change { Contact.exists?(mergee_contact.id) }.from(true).to(false)
    end

    it 'updates base_contact with merged attributes' do
      merge_service.send(:merge_and_remove_mergee_contact)
      base_contact.reload
      expect(base_contact.additional_attributes).to eq('field1' => 'value1', 'field2' => 'value2')
    end

    it 'prioritizes base_contact attributes' do
      base_contact.update(email: 'base@example.com')
      mergee_contact.update(email: 'mergee@example.com')

      merge_service.send(:merge_and_remove_mergee_contact)
      base_contact.reload
      expect(base_contact.email).to eq('base@example.com')
    end
  end
end
