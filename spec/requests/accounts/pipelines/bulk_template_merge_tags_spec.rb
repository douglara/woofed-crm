require 'rails_helper'

# Bulk send of a WhatsApp template whose variable is mapped to a contact field
# ({{contact.custom.codigo}}). Leads that have the value get an event; leads
# missing it are skipped (not dispatched, since WhatsApp would reject a blank
# variable) and reported.
RSpec.describe 'Bulk template send with merge tags', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let(:inbox) { JSON.parse(File.read('spec/integration/use_cases/accounts/apps/chatwoots/inbox_detail.json')) }
  let!(:chatwoot) { create(:apps_chatwoots, :skip_validate, account:, inboxes: [inbox]) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage) { create(:stage, pipeline:) }
  let!(:lead_with_data) do
    create(:deal, stage:, pipeline:,
                  contact: create(:contact, account:, full_name: 'Lorena', custom_attributes: { 'codigo' => 'A1' }))
  end
  let!(:lead_without_data) do
    create(:deal, stage:, pipeline:, contact: create(:contact, account:, full_name: 'João'))
  end

  before { sign_in(user) }

  it 'creates an event only for the lead that has the mapped value, and skips the other' do
    expect do
      post create_bulk_action_account_pipeline_path(account, pipeline),
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' },
           params: {
             event: {
               kind: 'chatwoot_message', app_type: 'Apps::Chatwoot', app_id: chatwoot.id, from_me: true,
               send_now: 'true', stage_id: stage.id, filter: '{}',
               additional_attributes: {
                 chatwoot_inbox_id: 101, chatwoot_template_name: 'lembrete_aula',
                 template_body_params: { '1' => '{{contact.custom.codigo}}', '2' => '14:00' }
               }
             }
           }
    end.to change(Event, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(Event.last.contact).to eq(lead_with_data.contact)
  end
end
