require 'rails_helper'

RSpec.describe Accounts::Contacts::EventsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account: account) }
  let!(:pipeline) { create(:pipeline, account: account) }
  let!(:stage) { create(:stage, account: account, pipeline: pipeline) }
  let!(:deal) { create(:deal, account: account, contact: contact, stage: stage) }
  
  let!(:valid_params) do
    {
      deal_id: deal.id,
      event: {
        account_id: account.id,
        contact_id: contact.id,
        title: 'Title event',
        content: 'activity content',
        scheduled_at: Time.now
      }
    }
  end

  describe 'POST /accounts/#{account.id}/contacts/#{contact.id}/events' do
    context 'when it is unthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/contacts/#{contact.id}/events"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'create event' do
        context 'create activity event' do
          it do
            params = valid_params.deep_merge(event: { kind: 'activity' })
            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events", 
                params: params 
            end.to change(Event, :count).by(1)
            expect(response).to redirect_to(new_account_contact_event_path(account_id: 
              account, contact_id: contact, deal_id: deal))
            expect(Event.first.kind).to eq(params[:event][:kind])
            expect(Event.first.done?).to eq(false)
          end
          it 'when acitvity event is done' do
            params_done = valid_params.deep_merge(event: { done: '1', kind: 'activity' })
            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events", 
                params: params_done 
            end.to change(Event, :count).by(1)
            expect(response).to redirect_to(new_account_contact_event_path(account_id: 
              account, contact_id: contact, deal_id: deal))
            expect(Event.first.kind).to eq(params_done[:event][:kind])
            expect(Event.first.done?).to eq(true)
          end
        end
        context 'create note event' do
          it do
            params = valid_params.deep_merge(event: { kind: 'note', done: '1' })
            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events", 
                params: params 
            end.to change(Event, :count).by(1)
            expect(response).to redirect_to(new_account_contact_event_path(account_id: 
              account, contact_id: contact, deal_id: deal))
            expect(Event.first.kind).to eq(params[:event][:kind])
            expect(Event.first.done?).to eq(true)
          end
        end
        context 'create chatwoot message event' do
          it do
            params = valid_params.deep_merge(event: { kind: 'chatwoot_message', done: '1', app_type: 'Apps::Chatwoot', app_id: chatwoot.id, chatwoot_inbox_id: 1 }).merge(send_now: 'true')
            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events", 
                params: params 
            end.to change(Event, :count).by(1)
            expect(response).to redirect_to(new_account_contact_event_path(account_id: 
              account, contact_id: contact, deal_id: deal))
            expect(Event.first.kind).to eq(params[:event][:kind])
            expect(Event.first.done?).to eq(true)
          end
          it 'when chatwoot message is scheduled' do
            params = valid_params.deep_merge(event: { kind: 'chatwoot_message', done: '0', app_type: 'Apps::Chatwoot', app_id: chatwoot.id, chatwoot_inbox_id: 1, scheduled_at: Time.zone.parse("2024-12-12 12:00:00") }).merge(send_now: 'false')
            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events", 
                params: params 
            end.to change(Event, :count).by(1)
            expect(response).to redirect_to(new_account_contact_event_path(account_id: 
              account, contact_id: contact, deal_id: deal))
            expect(Event.first.kind).to eq(params[:event][:kind])
            expect(Event.first.done?).to eq(false)
            expect(Event.first.scheduled_at).to eq(params[:event][:scheduled_at])
          end
        end
      end
    end
  end
  describe 'PATCH /accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}' do
    let(:event) { create(:event, account: account, contact: contact, deal: deal) }
    context 'when it is unthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'update event' do
        it do
          params = valid_params.deep_merge(event: { kind: 'activity', content: 'content updated' })
          expect do
            patch "/accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}", 
              params: params 
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(200)
          expect(Event.first.kind).to eq(params[:event][:kind])
          expect(Event.first.content.body.to_plain_text).to eq(params[:event][:content])
          expect(Event.first.done?).to eq(false)
        end
        it 'update event to done' do
          params = valid_params.deep_merge(event: { kind: 'activity', done: '1' })
          expect do
            patch "/accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}", 
              params: params 
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(200)
          expect(Event.first.kind).to eq(params[:event][:kind])
          expect(Event.first.done?).to eq(true)
        end
      end
    end
  end
  describe 'DELETE /accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}' do
    let(:event) { create(:event, account: account, contact: contact, deal: deal) }
    context 'when it is unthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'delete event' do
        it do
          expect do
            delete "/accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}", 
              params: {}
          end.to change(Event, :count).by(0)
          expect(response).to have_http_status(204)
        end
      end
    end
  end
end
