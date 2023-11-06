require 'rails_helper'

RSpec.describe Apps::ChatwootsController, type: :controller do
  describe 'POST #webhooks' do
    let(:apps_chatwoots) { create(:apps_chatwoots) }
    let(:user) { create(:user) }
    let(:account) { create(:account) }
    let(:deal) { create(:deal) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate)}
    let(:event_message) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/message/event.json") }
    it 'enqueues a background job and responds with 200 OK' do
      expect do
        post :webhooks, params: JSON.parse(event_message, symbolize_names: true)
      end.to change(Accounts::Apps::Chatwoots::Webhooks::ProcessWebhookWorker.jobs, :size).by(1)
      expect(response).to have_http_status(:ok)
      response_body = JSON.parse(response.body)
      expect(response_body['ok']).to eq(true)
    end
    context 'verify events kind' do
        it 'should message_created' do
            expect(JSON.parse(event_message, symbolize_names: true)[:event]).to eq('message_created')
        end
    end
  end
end


# RSpec.describe Accounts::Apps::Chatwoots::Webhooks::ImportMessage, type: :request do
#   describe 'POST /apps/chatwoots/webhooks' do
#     let(:apps_chatwoots) { create(:apps_chatwoots) }
#     let(:user) { create(:user) }
#     let(:account) { create(:account) }
#     let(:deal) { create(:deal) }
#     let(:chatwoot) { create(:apps_chatwoots, :skip_validate)}
#     let(:event) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/message/event.json") }
#     let(:response_conversations) { File.read("spec/integration/use_cases/accounts/apps/chatwoots/webhooks/events/response_conversations.json") }
#     INVALID_TOKEN = 'gfjjlasdasdhhk56'
#         # context "when it is an unauthenticated user" do
#         #     it 'returns unauthorizes' do
#         #         expect do 
#         #         post "/apps/chatwoots/webhooks",
#         #         headers: { 'Authorization' => "Bearer #{apps_chatwoots.chatwoot_user_token}"},
#         #         params: event,
#         #         as: :json
#         #         end.to change(Event, :count).by(0)
#         #         expect(response).to have_http_status(:unauthorized)
#         #     end
#         # end
#         context "when it is an Authenticated user" do
#             it "import chatwoot message event" do
#                 expect do                   
#                     post "/apps/chatwoots/webhooks",
#                     headers: { 'Authorization' => "Bearer #{apps_chatwoots.chatwoot_user_token}"},
#                     params: message_created,
#                     as: :json                                        
#                 end.to change(Event, :count).by(1)
#                 expect(response).to have_http_status(:success)
#                 expect(event.reload.kind).to eq('chatwoot_message')
#                 expect(event.reload.content.body.to_plain_text).to eq('Teste envio de mensagem do chatwoot para o woofed')
#             end
#             it "failed chatwoot message envent" do
                
#             end
#         end
#     end
# end

