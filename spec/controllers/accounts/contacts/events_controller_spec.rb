require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Accounts::Contacts::EventsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let!(:contact) { create(:contact) }
  let!(:chatwoot) { create(:apps_chatwoots, :skip_validate) }
  let(:evolution_api_connected) { create(:apps_evolution_api, :connected) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage) { create(:stage, pipeline:) }
  let!(:deal) { create(:deal, contact:, stage:) }
  let(:conversation_response) do
    File.read('spec/integration/use_cases/accounts/apps/chatwoots/get_conversations.json')
  end
  let(:create_conversation_response) do
    File.read('spec/integration/use_cases/accounts/apps/chatwoots/create_conversation.json')
  end
  let(:message_response) { File.read('spec/integration/use_cases/accounts/apps/chatwoots/send_message.json') }
  let(:send_text_response) do
    File.read('spec/integration/use_cases/accounts/apps/evolution_api/message/send_text_response.json')
  end
  let(:invalid_send_text_response) do
    File.read('spec/integration/use_cases/accounts/apps/evolution_api/message/invalid_send_text_response.json')
  end
  def get_file(name)
    Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/files/#{name}")
  end
  let(:event_created) { Event.last }

  let!(:valid_params) do
    {
      deal_id: deal.id,
      event: {
        account_id: account.id,
        contact_id: contact.id,
        title: 'Event 1',
        content: 'Hi Lorena',
        from_me: true,
        deal_id: deal.id,
        scheduled_at: Time.now
      }
    }
  end

  describe 'POST /accounts/{account.id}/contacts/{contact.id}/events' do
    context 'when it is unthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/contacts/#{contact.id}/events"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
        stub_request(:post, /messages/)
          .to_return(body: message_response, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:get, /conversations/)
          .to_return(body: { payload: [] }.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, /conversations/)
          .to_return(body: create_conversation_response, status: 200, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, /sendText/)
          .to_return(body: send_text_response, status: 201, headers: { 'Content-Type' => 'application/json' })
      end

      context 'create event' do
        context 'create activity event' do
          it do
            params = valid_params.deep_merge(event: { kind: 'activity' })
            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                   params:
            end.to change(Event, :count).by(1)
            expect(response).to redirect_to(new_account_contact_event_path(account_id:
              account, contact_id: contact, deal_id: deal))
            expect(event_created.kind).to eq(params[:event][:kind])
            expect(event_created.done?).to eq(false)
            expect(event_created.deal).to eq(deal)
          end
          it 'when acitvity event is done' do
            params_done = valid_params.deep_merge(event: { done: '1', kind: 'activity' })
            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                   params: params_done
            end.to change(Event, :count).by(1)
            expect(response).to redirect_to(new_account_contact_event_path(account_id:
              account, contact_id: contact, deal_id: deal))
            expect(event_created.kind).to eq(params_done[:event][:kind])
            expect(event_created.done?).to eq(true)
          end
          context 'when there are files' do
            context 'when there are 6 valid files' do
              it 'should create 6 events with and 6 attachments' do
                files = [get_file('patrick.png'), get_file('audio_test.oga'),
                         get_file('video_test.mp4'), get_file('hello_world.txt'), get_file('hello_world.rar'), get_file('hello_world.json')]
                params = valid_params.deep_merge(event: { kind: 'activity',
                                                          files: })
                Event.delete_all
                expect do
                  post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                       params:
                end.to change(Event, :count).by(6)
                                            .and change(Attachment, :count).by(6)
                expect(response).to redirect_to(new_account_contact_event_path(account_id:
                  account, contact_id: contact, deal_id: deal))
                expect(Attachment.pluck(:file_type)).to match_array(%w[image audio video file file file])
                events_with_content = Event.select do |event|
                  event&.content&.body&.to_plain_text == params[:event][:content]
                end
                expect(events_with_content.size).to eq(1)
                expect(events_with_content.sample).to eq(Event.first)
              end
            end
            context 'when there are 1 valid file and 1 invalid file' do
              it 'should not create events' do
                files =  [get_file('patrick.png'), 'invalid_file']
                params = valid_params.deep_merge(event: { kind: 'activity',
                                                          files: })
                expect do
                  post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                       params:
                end.to change(Event, :count).by(0)
                expect(response).to have_http_status(:unprocessable_entity)
              end
            end
          end
        end
        context 'create note event' do
          it do
            params = valid_params.deep_merge(event: { kind: 'note' })
            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                   params:
            end.to change(Event, :count).by(1)
            expect(response).to redirect_to(new_account_contact_event_path(account_id:
              account, contact_id: contact, deal_id: deal))
            expect(event_created.kind).to eq(params[:event][:kind])
            expect(event_created.done?).to eq(true)
          end
        end
        context 'create chatwoot message event' do
          around(:each) do |example|
            Sidekiq::Testing.inline! do
              example.run
            end
          end

          it do
            params = valid_params.deep_merge(event: { kind: 'chatwoot_message', app_type: 'Apps::Chatwoot',
                                                      app_id: chatwoot.id, chatwoot_inbox_id: 2, send_now: 'true' })

            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                   params:
            end.to change(Event, :count).by(1)

            expect(event_created.kind).to eq(params[:event][:kind])
            expect(event_created.done?).to eq(true)
          end

          it 'when chatwoot message is scheduled' do
            params = valid_params.deep_merge(event: { kind: 'chatwoot_message', done: '0', app_type: 'Apps::Chatwoot',
                                                      app_id: chatwoot.id, chatwoot_inbox_id: 1, scheduled_at: (Time.current + 2.hours).round, send_now: 'false' })
            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                   params:
            end.to change(Event, :count).by(1)
            expect(response).to redirect_to(new_account_contact_event_path(account_id:
              account, contact_id: contact, deal_id: deal))
            expect(event_created.kind).to eq(params[:event][:kind])
            expect(event_created.done?).to eq(false)
            expect(event_created.scheduled_at.round).to eq(params[:event][:scheduled_at])
          end
          context 'when chatwoot message is scheduled and delivered' do
            it do
              params = valid_params.deep_merge(event: { kind: 'chatwoot_message', done: '0',
                                                        app_type: 'Apps::Chatwoot', app_id: chatwoot.id, chatwoot_inbox_id: 1, scheduled_at: (Time.current + 2.hours).round, auto_done: true, send_now: 'false' })
              expect do
                post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                     params:
              end.to change(Event, :count).by(1)
              expect(response).to redirect_to(new_account_contact_event_path(account_id:
                account, contact_id: contact, deal_id: deal))
              expect(event_created.kind).to eq(params[:event][:kind])
              expect(event_created.done?).to eq(false)
              expect(event_created.scheduled_at.round).to eq(params[:event][:scheduled_at])
              travel(1.hours) do
                GoodJob.perform_inline
                expect(event_created.reload.done?).to eq(false)
              end
              travel(3.hours) do
                GoodJob.perform_inline
                expect(event_created.reload.done?).to eq(true)
              end
            end
          end
        end
      end
      context 'create evolution api message event' do
        around(:each) do |example|
          Sidekiq::Testing.inline! do
            example.run
          end
        end

        it do
          params = valid_params.deep_merge(event: { kind: 'evolution_api_message', app_type: 'Apps::EvolutionApi',
                                                    app_id: evolution_api_connected.id, send_now: 'true' })

          expect do
            post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                 params:
          end.to change(Event, :count).by(1)
          expect(event_created.kind).to eq(params[:event][:kind])
          expect(event_created.done?).to eq(true)
        end

        it 'when evolution_api message is scheduled' do
          params = valid_params.deep_merge(event: { kind: 'evolution_api_message', done: '0', app_type: 'Apps::EvolutionApi',
                                                    app_id: evolution_api_connected.id, scheduled_at: (Time.current + 2.hours).round, send_now: 'false' })
          expect do
            post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                 params:
          end.to change(Event, :count).by(1)
          expect(response).to redirect_to(new_account_contact_event_path(account_id:
            account, contact_id: contact, deal_id: deal))
          expect(event_created.kind).to eq(params[:event][:kind])
          expect(event_created.done?).to eq(false)
          expect(event_created.scheduled_at.round).to eq(params[:event][:scheduled_at])
        end
        context 'when contact there is not phone number' do
          before do
            stub_request(:post, /sendText/)
              .to_return(body: invalid_send_text_response, status: 400, headers: { 'Content-Type' => 'application/json' })
            stub_request(:post, /contacts/)
              .to_return(body: invalid_send_text_response, status: 400, headers: { 'Content-Type' => 'application/json' })
          end
          let(:contact_no_phone) { create(:contact, phone: '') }
          it 'done should return false' do
            params = valid_params.deep_merge(event: { kind: 'evolution_api_message', app_type: 'Apps::EvolutionApi',
                                                      app_id: evolution_api_connected.id, send_now: 'true' })

            expect do
              post "/accounts/#{account.id}/contacts/#{contact_no_phone.id}/events",
                   params:
            end.to change(Event, :count).by(1)
            expect(event_created.kind).to eq(params[:event][:kind])
            expect(event_created.done?).to eq(false)
          end
        end

        context 'when evolution_api message is scheduled and delivered' do
          it do
            params = valid_params.deep_merge(event: { kind: 'evolution_api_message', done: '0',
                                                      app_type: 'Apps::EvolutionApi', app_id: evolution_api_connected.id, scheduled_at: (Time.current + 2.hours).round, auto_done: true, send_now: 'false' })
            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                   params:
            end.to change(Event, :count).by(1)
            expect(response).to redirect_to(new_account_contact_event_path(account_id:
              account, contact_id: contact, deal_id: deal))
            expect(event_created.kind).to eq(params[:event][:kind])
            expect(event_created.done?).to eq(false)
            expect(event_created.scheduled_at.round).to eq(params[:event][:scheduled_at])
            travel(1.hours) do
              GoodJob.perform_inline
              expect(event_created.reload.done?).to eq(false)
            end
            travel(3.hours) do
              GoodJob.perform_inline
              expect(event_created.reload.done?).to eq(true)
            end
          end
        end
      end
      context 'when there is user with push notification enabled' do
        let!(:user_webpush_enable) { create(:user, :push_notifications_enabled, email: 'teste@test.com') }
        context 'when there is a valid webpush subscription' do
          before do
            allow(WebPush).to receive(:payload_send).and_return(double(Net::HTTPCreated, code: '201',
                                                                                         message: 'Created', read_body: true))
          end
          let!(:webpush_subscription) { create(:webpush_subscription, user: user_webpush_enable) }
          it 'should send webpush notification' do
            params = valid_params.deep_merge(event: { kind: 'activity' })
            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                   params:
            end.to change(Event, :count).by(1)
            expect(response).to redirect_to(new_account_contact_event_path(account_id:
              account, contact_id: contact, deal_id: deal))
            expect(event_created.kind).to eq(params[:event][:kind])
            expect(event_created.done?).to eq(false)
            expect(event_created.deal).to eq(deal)
          end
        end
        context 'when there is a invalid webpush subscription' do
          let!(:webpush_subscription) { create(:webpush_subscription, :valid, user: user_webpush_enable) }

          before do
            stub_request(:post, /send/)
              .to_return(status: 410, body: '', headers: {})
          end

          it 'should not send and destroy webpush notification' do
            params = valid_params.deep_merge(event: { kind: 'activity' })
            expect do
              post "/accounts/#{account.id}/contacts/#{contact.id}/events",
                   params:
            end.to change(Event, :count).by(1)
                                        .and change(WebpushSubscription, :count).by(-1)
            expect(response).to redirect_to(new_account_contact_event_path(account_id:
              account, contact_id: contact, deal_id: deal))
            expect(event_created.kind).to eq(params[:event][:kind])
            expect(event_created.done?).to eq(false)
            expect(event_created.deal).to eq(deal)
          end
        end
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/contacts/{contact.id}/events/{event.id}' do
    before do
      stub_request(:get, /conversations/).to_return(body: conversation_response, status: 200,
                                                    headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, /conversations/).to_return(body: create_conversation_response, status: 200,
                                                     headers: { 'Content-Type' => 'application/json' })
    end

    let(:event) { create(:event, contact:, deal:, kind: 'activity') }
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
                  params:
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(200)
          expect(event_created.kind).to eq(params[:event][:kind])
          expect(event_created.content.body.to_plain_text).to eq(params[:event][:content])
          expect(event_created.done?).to eq(false)
        end
        it 'update event to done' do
          params = valid_params.deep_merge(event: { kind: 'activity', done: '1' })
          expect do
            patch "/accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}",
                  params:
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(200)
          expect(event_created.kind).to eq(params[:event][:kind])
          expect(event_created.done?).to eq(true)
        end
        it 'update overdue activity event to done with send_now' do
          params = valid_params.deep_merge(event: { kind: 'activity', send_now: 'true' })
          expect do
            patch "/accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}",
                  params:
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(200)
          expect(event_created.kind).to eq(params[:event][:kind])
          expect(event_created.done?).to eq(true)
        end
        it 'update scheduled activity event to done with send_now' do
          params = valid_params.deep_merge(event: { kind: 'activity', send_now: 'true' })
          expect do
            patch "/accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}",
                  params:
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(200)
          expect(event_created.kind).to eq(params[:event][:kind])
          expect(event_created.done?).to eq(true)
        end
        it 'update planned activity event to done with send_now' do
          valid_params[:event][:scheduled_at] = Time.current + 5.days
          params = valid_params.deep_merge(event: { kind: 'activity', send_now: 'true' })
          expect do
            patch "/accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}",
                  params:
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(200)
          expect(event_created.kind).to eq(params[:event][:kind])
          expect(event_created.done?).to eq(true)
        end
        it 'update planned chatwoot message event to done with send_now' do
          valid_params[:event].delete(:scheduled_at)
          params = valid_params.deep_merge(event: { kind: 'chatwoot_message', send_now: 'true',
                                                    app_type: 'Apps::Chatwoot', app_id: chatwoot.id, chatwoot_inbox_id: 1 })
          expect do
            patch "/accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}",
                  params:
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(200)
          expect(event_created.kind).to eq(params[:event][:kind])
          expect(event_created.done?).to eq(true)
        end
        it 'update overdue chatwoot message event to done with send_now' do
          params = valid_params.deep_merge(event: { kind: 'chatwoot_message', send_now: 'true',
                                                    app_type: 'Apps::Chatwoot', app_id: chatwoot.id, chatwoot_inbox_id: 1 })
          expect do
            patch "/accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}",
                  params:
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(200)
          expect(event_created.kind).to eq(params[:event][:kind])
          expect(event_created.done?).to eq(true)
        end
        it 'update scheduled chatwoot message event to done with send_now' do
          valid_params[:event][:scheduled_at] = Time.current + 5.days
          params = valid_params.deep_merge(event: { kind: 'chatwoot_message', send_now: 'true',
                                                    app_type: 'Apps::Chatwoot', app_id: chatwoot.id, chatwoot_inbox_id: 1 })
          expect do
            patch "/accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}",
                  params:
          end.to change(Event, :count).by(1)
          expect(response).to have_http_status(200)
          expect(event_created.kind).to eq(params[:event][:kind])
          expect(event_created.done?).to eq(true)
        end
      end
    end
  end
  describe 'DELETE /accounts/#{account.id}/contacts/#{contact.id}/events/#{event.id}' do
    let(:event) { create(:event, contact:, deal:, kind: 'activity') }
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

  describe 'GET /accounts/{account.id}/contacts/{contact.id}/events/new' do
    context 'when it is unthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/contacts/#{contact.id}/events/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'get events new page' do
        it do
          get "/accounts/#{account.id}/contacts/#{contact.id}/events/new",
          params: { deal_id: deal.id }
          expect(response).to have_http_status(200)
          expect(response.body).to include('Note')
          expect(response.body).to include('Activity')
          expect(response.body).to include('chatwoot_message')
          expect(response.body).not_to include('evolution_api_message')
        end
        context 'when there is whatsapp integration' do
          let!(:evolution_api) { create(:apps_evolution_api, account:) }

          it 'should show chatwoot button on event form' do
            get "/accounts/#{account.id}/contacts/#{contact.id}/events/new",
            params: { deal_id: deal.id }
            expect(response).to have_http_status(200)
            expect(response.body).to include('Note')
            expect(response.body).to include('Activity')
            expect(response.body).to include('chatwoot_message')
            expect(response.body).to include('evolution_api_message')
          end
        end
      end
    end
  end
end
