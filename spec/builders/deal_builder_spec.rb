require 'rails_helper'
require 'action_controller'

RSpec.describe DealBuilder do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage) { create(:stage, pipeline:) }
  let(:params) do
    ActionController::Parameters.new(
      name: 'Deal without contact',
      status: 'open',
      stage_id: stage.id,
      contact_attributes: {
        full_name: 'Jane Doe',
        email: 'jane@example.com'
      }
    )
  end
  let(:subject) { described_class.new(user, params) }
  let(:deal_mock) { instance_double(Deal) }

  describe '#perform' do
    it 'calls #build and returns its result' do
      expect(subject).to receive(:build).and_return(deal_mock)
      result = subject.perform
      expect(result).to eq(deal_mock)
    end
  end

  describe '#build' do
    let!(:contact) { create(:contact) }

    context 'when contact_attributes is provided' do
      context 'when the email or phone matches an existing contact' do
        let(:params) do
          ActionController::Parameters.new(
            name: 'Deal test name',
            status: 'open',
            stage_id: stage.id,
            contact_attributes: {
              full_name: 'Jane Doe',
              email: contact.email
            }
          )
        end

        it 'builds a deal, assigns the user and uses existing contact' do
          expect(ContactBuilder).to receive(:new).and_call_original
          deal = subject.build

          expect(deal).to be_a_new(Deal)
          expect(deal.contact).not_to be_a_new(Contact)
          expect(deal.name).to eq('Deal test name')
          expect(deal.status).to eq('open')
          expect(deal.stage).to eq(stage)
          expect(deal.contact).to eq(contact)
          expect(deal.deal_assignees.first.user).to eq(user)
        end
      end
      context 'when the email or phone does not match any existing contact' do
        let(:params) do
          ActionController::Parameters.new(
            name: 'Deal test name',
            status: 'open',
            stage_id: stage.id,
            contact_attributes: {
              full_name: 'Jane Doe',
              email: 'jane@example.com'
            }
          )
        end

        it 'builds a deal, builds a contact, and assigns the user' do
          expect(ContactBuilder).to receive(:new).and_call_original
          deal = subject.build

          expect(deal).to be_a_new(Deal)
          expect(deal.contact).to be_a_new(Contact)
          expect(deal.name).to eq('Deal test name')
          expect(deal.status).to eq('open')
          expect(deal.stage).to eq(stage)
          expect(deal.contact).to be_present
          expect(deal.contact.full_name).to eq('Jane Doe')
          expect(deal.contact.email).to eq('jane@example.com')
          expect(deal.deal_assignees.first.user).to eq(user)
        end
      end
    end

    context 'when contact_id is provided' do
      let(:params) do
        ActionController::Parameters.new(
          name: 'With existing contact',
          status: 'won',
          stage_id: stage.id,
          contact_id: contact.id
        )
      end

      it 'does not call ContactBuilder and uses existing contact to builds a deal' do
        deal = subject.build
        expect(ContactBuilder).not_to receive(:new)

        expect(deal).to be_a_new(Deal)
        expect(deal.name).to eq('With existing contact')
        expect(deal.status).to eq('won')
        expect(deal.stage).to eq(stage)
        expect(deal.contact).to eq(contact)
        expect(deal.deal_assignees.first.user).to eq(user)
      end
    end
  end

  describe '#attach_contact_if_needed' do
    before do
      allow(subject).to receive(:deal).and_return(deal_mock)
    end

    context 'when contact_id is provided' do
      let(:params) do
        ActionController::Parameters.new(
          name: 'With existing contact',
          status: 'won',
          stage_id: stage.id,
          contact_id: 1
        )
      end

      it 'does not call ContactBuilder and return' do
        subject.send(:attach_contact_if_needed)
        expect(ContactBuilder).not_to receive(:new)
      end
    end

    context 'when contact_attributes is blank' do
      let(:params) do
        ActionController::Parameters.new(
          name: 'With existing contact',
          status: 'won',
          stage_id: stage.id
        )
      end

      it 'does not call ContactBuilder and return' do
        subject.send(:attach_contact_if_needed)
        expect(ContactBuilder).not_to receive(:new)
      end
    end

    context 'when contact_attributes is provided' do
      let(:params) do
        ActionController::Parameters.new(
          name: 'With existing contact',
          status: 'won',
          stage_id: stage.id,
          contact_attributes: {
            full_name: 'Jane Doe',
            email: 'jane@example.com'
          }
        )
      end

      it 'does call ContactBuilder and assigns the contact to the deal' do
        allow(subject).to receive(:deal).and_return(deal_mock)
        allow(deal_mock).to receive(:contact=)
        expect(ContactBuilder).to receive(:new).and_call_original

        subject.send(:attach_contact_if_needed)
      end
    end
  end
end
