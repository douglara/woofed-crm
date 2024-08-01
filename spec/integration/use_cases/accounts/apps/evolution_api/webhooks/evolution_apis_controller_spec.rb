require 'rails_helper'
require 'webmock/rspec'
require 'sidekiq/testing'

RSpec.describe Apps::EvolutionApisController, type: :request do
  let(:account) { create(:account) }
  let!(:contact) { create(:contact, account: account) }
  let(:deal) { create(:deal, account: account) }
  let(:stage) { create(:stage, account: account, pipeline: pipeline) }
  let(:deal) { create(:deal, account: account, contact: contact, stage: stage) }
  let(:delete_instance_response) do
    File.read('spec/integration/use_cases/accounts/apps/evolution_api/instance/delete_response.json')
  end
  let(:group_message) do
    message_hash = JSON.parse(File.read('spec/integration/use_cases/accounts/apps/evolution_api/webhooks/events/group_import_conversation_message_event.json'))
    message_hash['instance'] = evolution_api_connected.instance
    message_hash['apikey'] = evolution_api_connected.token
    message_hash
  end

  def qrcode_updated_webhook_event_params(evolution_api)
    {
      "event": 'qrcode.updated',
      "instance": evolution_api.instance,
      "data": {
        "qrcode": {
          "instance": evolution_api.instance,
          "pairingCode": 'V37R3T7X',
          "code": '2@xCLTLQpXqmnR1jld2wKbVGmXchdVSFR3QHQa+6BNF8EK8VeoKUTYklFySHt0rrgknAPgwBkD7y1IIQ==,Xl787d38Gmn0wbPMtlvd47VIqs1xzfsZQTTLgePiYmA=,XQTEs9Fx080JHolGhWrlheRKQo8WCPj0DqCbrrMLiU8=,r8hWahUUJqu7BJFq1l1dQopW2r3lEbOrWOyQJfmmZdY=',
          "base64": 'qrcode'
        }
      },
      "destination": 'https://webhook.com/',
      "date_time": '2024-01-27T02:35:43.230Z',
      "server_url": 'https://server.com',
      "apikey": evolution_api.token
    }
  end

  def import_conversation_message_params(evolution_api, contact_name, contact_phone)
    {
      "event": 'messages.upsert',
      "instance": evolution_api.instance,
      "data": {
        "key": {
          "remoteJid": "#{contact_phone.sub(/\+/, '')}@s.whatsapp.net",
          "fromMe": true,
          "id": '3A58500B6F6FDA9A5576'
        },
        "pushName": contact_name,
        "message": {
          "conversation": 'Teste'
        },
        "messageType": 'conversation',
        "messageTimestamp": 1_707_368_285,
        "owner": evolution_api.instance,
        "source": 'ios'
      },
      "destination": 'https://webhookwoofed.site',
      "date_time": '2024-02-08T01:58:05.737Z',
      "sender": "#{evolution_api.phone.sub(/\+/, '')}@s.whatsapp.net",
      "server_url": evolution_api.endpoint_url,
      "apikey": evolution_api.token
    }
  end

  def import_extended_text_message_params(evolution_api, contact_name, contact_phone, from_me = false)
    {
      "event": 'messages.upsert',
      "instance": evolution_api.instance,
      "data": {
        "key": {
          "remoteJid": "#{contact_phone.sub(/\+/, '')}@s.whatsapp.net",
          "fromMe": from_me,
          "id": '1AECB65CE8AC2CB38486D898090B5C87'
        },
        "pushName": contact_name,
        "message": {
          "extendedTextMessage": {
            "text": 'Teste',
            "previewType": 'NONE',
            "contextInfo": {
              "entryPointConversionSource": 'global_search_new_chat',
              "entryPointConversionApp": 'whatsapp',
              "entryPointConversionDelaySeconds": 2
            },
            "inviteLinkGroupTypeV2": 'DEFAULT'
          },
          "messageContextInfo": {
            "deviceListMetadata": {
              "recipientKeyHash": 'PWJRRJVMiX4NIQ==',
              "recipientTimestamp": '1707339780'
            },
            "deviceListMetadataVersion": 2
          }
        },
        "messageType": 'extendedTextMessage',
        "messageTimestamp": 1_707_339_876,
        "owner": evolution_api.instance,
        "source": 'android'
      },
      "destination": 'https://webhookwoofed.site/',
      "date_time": '2024-02-07T18:04:36.189Z',
      "sender": "#{evolution_api.phone.sub(/\+/, '')}@s.whatsapp.net",
      "server_url": evolution_api.endpoint_url,
      "apikey": evolution_api.token
    }
  end

  def connection_event_params(evolution_api, status_reason, status = 'open')
    {
      "event": 'connection.update',
      "instance": evolution_api.instance,
      "data": {
        "instance": evolution_api.instance,
        "state": status,
        "statusReason": status_reason
      },
      "destination": 'https://webhook.com/',
      "date_time": '2024-01-27T01:19:47.979Z',
      "sender": '5522999999999@s.whatsapp.net',
      "server_url": 'https://app-beta.woofedcrm.com/',
      "apikey": evolution_api.token
    }
  end

  def post_webhook(event_data)
    Sidekiq::Testing.inline! { post '/apps/evolution_apis/webhooks', params: event_data }
  end

  def expect_success
    expect(response).to have_http_status(200)
    expect(JSON.parse(response.body)).to eq({ 'ok' => true })
  end

  describe 'POST /apps/evolution_apis/webhooks' do
    describe 'when evolution_api is connecting' do
      let!(:evolution_api_connecting) { create(:apps_evolution_api, :connecting, account: account) }
      context 'when is qrcode_update event' do
        it 'should update qrcode' do
          expect do
            post_webhook(qrcode_updated_webhook_event_params(evolution_api_connecting))
          end.to change { evolution_api_connecting.reload.qrcode }.from('qrcode_connecting').to('qrcode')
          expect_success
        end
      end
      context 'when is created_connection event' do
        it 'should update evolution_api status, phone and qrcode' do
          post_webhook(connection_event_params(evolution_api_connecting, 200))
          expect_success
          expect(evolution_api_connecting.reload.connected?).to be_truthy
          expect(evolution_api_connecting.phone).to be_present
          expect(evolution_api_connecting.qrcode).not_to be_present
        end
      end
      context 'when is deleted_connection event' do
        it 'should update evolution_api status' do
          stub_request(:delete, /delete/)
            .to_return(body: delete_instance_response.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
          stub_request(:get, /#{evolution_api_connecting.instance}/)
            .to_return(body: '{"instance": {"instanceName": "649b28ca46f21e45b843", "state": "close"}}', status: 200, headers: { 'Content-Type' => 'application/json' })
          post_webhook(connection_event_params(evolution_api_connecting, 401, 'close'))
          expect_success
          expect(evolution_api_connecting.reload.disconnected?).to be_truthy
        end
      end
    end
    describe 'when evolution_api is connected' do
      let!(:evolution_api_connected) { create(:apps_evolution_api, :connected, account: account) }
      context 'when is qrcode_update event' do
        it 'evolution_api should not be changed' do
          post_webhook(qrcode_updated_webhook_event_params(evolution_api_connected))
          expect_success
          expect(evolution_api_connected.reload.changed?).to be_falsey
        end
      end
      context 'when is deleted_connection event' do
        it 'should update evolution_api status' do
          stub_request(:delete, /delete/)
            .to_return(body: delete_instance_response.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
          stub_request(:get, /#{evolution_api_connected.instance}/)
            .to_return(body: '{"instance": {"instanceName": "4afc8d8323e72b79289d", "state": "close"}}', status: 200, headers: { 'Content-Type' => 'application/json' })
          post_webhook(connection_event_params(evolution_api_connected, 401, 'close'))
          expect_success
          expect(evolution_api_connected.reload.disconnected?).to be_truthy
        end
      end
      context 'when is messages_upset event' do
        context 'when is extended text message webhook' do
          it 'should create an event' do
            post_webhook(import_extended_text_message_params(evolution_api_connected, contact.full_name, contact.phone))
            expect_success
            expect(contact.reload.events.count).to eq(1)
            expect(contact.events.first.evolution_api_message?).to be_truthy
            expect(contact.events.first.additional_attributes).to include({ 'message_id' => '1AECB65CE8AC2CB38486D898090B5C87' })
          end
          context 'when contact does not exist' do
            it 'should create contact and event' do
              expect do
                post_webhook(import_extended_text_message_params(evolution_api_connected, 'contact test not exist',
                                                                 '5522998813788'))
              end.to change(Contact, :count).to eq(2)
              expect_success
              expect(Event.all.count).to eq(1)
              expect(Contact.count).to eq(2)
              expect(Contact.where('full_name = ? and phone = ? ', 'contact test not exist',
                                   '+5522998813788').count).to eq(1)
            end
            context 'when webhook data from_me is true' do
              it 'should create a contact with no full_name and event' do
                expect do
                  post_webhook(import_extended_text_message_params(evolution_api_connected, 'contact test not exist',
                                                                   '5522998813788', true))
                end.to change(Contact, :count).to eq(2)
                expect_success
                expect(Event.all.count).to eq(1)
                expect(Contact.count).to eq(2)
                expect(Contact.where('full_name = ? AND phone = ?', '', '+5522998813788').count).to eq(1)
              end
            end
          end
          context 'when contact exists' do
            context 'when full_name is blank' do
              let!(:contact_full_name_blank) { create(:contact, phone: '+5522998813788', full_name: '') }
              context 'when webhook data from_me is true' do
                it 'should not update contact full_name' do
                  post_webhook(import_extended_text_message_params(evolution_api_connected, 'contact test',
                                                                   '5522998813788', true))

                  expect_success
                  expect(Event.all.count).to eq(1)
                  expect(Contact.count).to eq(2)
                  expect(Contact.where('full_name = ? AND phone = ?', '',
                                       '+5522998813788').count).to eq(1)
                end
              end
              context 'when webhook data from_me is false' do
                it 'should update contact full_name' do
                  post_webhook(import_extended_text_message_params(evolution_api_connected, 'contact test',
                                                                   '5522998813788'))

                  expect_success
                  expect(Event.all.count).to eq(1)
                  expect(Contact.count).to eq(2)
                  expect(Contact.where('full_name = ? AND phone = ?', 'contact test',
                                       '+5522998813788').count).to eq(1)
                end
              end
            end
            context 'when full_name is not blank' do
              context 'when webhook data from_me is true' do
                it 'should not update contact full_name' do
                  post_webhook(import_extended_text_message_params(evolution_api_connected, 'contact test',
                                                                   contact.phone, true))

                  expect_success
                  expect(Event.all.count).to eq(1)
                  expect(Contact.count).to eq(1)
                  expect(Contact.where('full_name = ? AND phone = ?', contact.full_name,
                                       contact.phone).count).to eq(1)
                end
              end
              context 'when webhook data from_me is false' do
                it 'should not update contact full_name' do
                  post_webhook(import_extended_text_message_params(evolution_api_connected, 'contact test',
                                                                   contact.phone))

                  expect_success
                  expect(Event.all.count).to eq(1)
                  expect(Contact.count).to eq(1)
                  expect(Contact.where('full_name = ? AND phone = ?', contact.full_name,
                                       contact.phone).count).to eq(1)
                end
              end
            end
          end
        end
        context 'when is conversation message webhook' do
          it 'should create an event' do
            post_webhook(import_conversation_message_params(evolution_api_connected, contact.full_name, contact.phone))
            expect_success
            expect(contact.reload.events.count).to eq(1)
            expect(contact.events.first.evolution_api_message?).to be_truthy
          end
        end
        context 'when is group message' do
          let!(:user) { create(:user, account: account) }
          let!(:contact) do
            create(:contact, account: account, phone: '',
                             additional_attributes: { group_id: '120363103459410972@g.us' })
          end

          it 'should create an event' do
            stub_request(:get, /findGroupInfos/)
              .to_return(body: '{"id":"120363103459410972@g.us","subject":"Teste 32","subjectOwner":"554196910256@s.whatsapp.net","subjectTime":1713478239,"size":2,"creation":1679567724,"owner":"554192342890@s.whatsapp.net","restrict":false,"announce":false,"isCommunity":false,"isCommunityAnnounce":false,"memberAddMode":false,"participants":[{"id":"554192342890@s.whatsapp.net","admin":"superadmin"},{"id":"554196910256@s.whatsapp.net","admin":null}]}',
                         status: 200, headers: { 'Content-Type' => 'application/json' })

            post_webhook(group_message)
            expect_success
            expect(contact.reload.events.count).to eq(1)
            expect(contact.events.first.evolution_api_message?).to be_truthy
            expect(contact.additional_attributes['group_id']).to eq('120363103459410972@g.us')
            expect(contact.reload.full_name).to eq('Teste 32 - Grupo')
          end
        end
      end
    end
    describe 'when evolution_api is disconnected' do
      let!(:evolution_api) { create(:apps_evolution_api, account: account) }
      context 'when is qrcode_update event' do
        it 'evolution_api should not be changed' do
          post_webhook(qrcode_updated_webhook_event_params(evolution_api))
          expect_success
          expect(evolution_api.reload.changed?).to be_falsey
        end
      end
      context 'when is deleted_connection event' do
        it 'evolution_api should not be changed' do
          post_webhook(connection_event_params(evolution_api, 401, 'close'))
          expect_success
          expect(evolution_api.reload.changed?).to be_falsey
        end
      end
      context 'when is messages_upset event' do
        context 'when is extended text message webhook' do
          it 'should not create event' do
            post_webhook(import_extended_text_message_params(evolution_api, contact.full_name, contact.phone))
            expect_success
            expect(contact.reload.events.count).to eq(0)
          end
        end
        context 'when is conversation message webhook' do
          it 'should not create event' do
            post_webhook(import_conversation_message_params(evolution_api, contact.full_name, contact.phone))
            expect_success
            expect(contact.reload.events.count).to eq(0)
          end
        end
      end
    end
  end
end
