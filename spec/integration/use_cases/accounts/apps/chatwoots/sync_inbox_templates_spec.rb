require 'rails_helper'

RSpec.describe Accounts::Apps::Chatwoots::SyncInboxTemplates, type: :request do
  let(:chatwoot) { create(:apps_chatwoots, :skip_validate) }
  let(:inbox_detail) { File.read('spec/integration/use_cases/accounts/apps/chatwoots/inbox_detail.json') }
  let(:inboxes) do
    [{ 'id' => 101, 'name' => 'Official WhatsApp', 'channel_type' => 'Channel::Whatsapp' },
     { 'id' => 200, 'name' => 'Evolution', 'channel_type' => 'Channel::Api' }]
  end

  def detail_url(inbox_id)
    "#{chatwoot.chatwoot_endpoint_url}/api/v1/accounts/#{chatwoot.chatwoot_account_id}/inboxes/#{inbox_id}"
  end

  it 'enriches whatsapp inboxes with approved templates and leaves other channels untouched' do
    stub_request(:get, detail_url(101))
      .to_return(body: inbox_detail, status: 200, headers: { 'Content-Type' => 'application/json' })

    result = described_class.call(chatwoot, inboxes)
    whatsapp = result.find { |inbox| inbox['id'] == 101 }
    evolution = result.find { |inbox| inbox['id'] == 200 }

    expect(whatsapp['message_templates'].map { |template| template['name'] })
      .to match_array(%w[lembrete_aula appointment_confirmation flight_confirmation validation_code])
    expect(whatsapp['message_templates']).to all(include('name', 'language', 'category', 'components'))
    expect(evolution).not_to have_key('message_templates')
  end

  it 'keeps the inbox untouched when the detail request fails' do
    stub_request(:get, detail_url(101)).to_return(status: 500, body: 'error')

    result = described_class.call(chatwoot, inboxes)
    expect(result.find { |inbox| inbox['id'] == 101 }).not_to have_key('message_templates')
  end

  it 'returns the input unchanged when it is not an array' do
    expect(described_class.call(chatwoot, nil)).to be_nil
  end
end
