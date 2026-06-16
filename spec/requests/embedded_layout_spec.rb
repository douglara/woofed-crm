require 'rails_helper'

# Level 1 of the Chatwoot widget: when a page renders inside the embedded iframe
# it must drop the WoofedCRM chrome (sidebar + navbar) so it feels native to
# Chatwoot. "Woofed AI" is a sidebar menu label, used here as a chrome marker.
RSpec.describe 'Embedded chrome-less rendering', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let(:path) { account_contacts_path(account) }

  before { sign_in user }

  it 'renders the sidebar and navbar by default' do
    get path

    expect(response).to be_successful
    expect(response.body).to include('Woofed AI')
  end

  it 'hides the sidebar and navbar when the request is embedded' do
    get path, params: { embed: '1' }

    expect(response).to be_successful
    expect(response.body).not_to include('Woofed AI')
  end

  it 'hides the chrome when loaded inside an iframe (Sec-Fetch-Dest: iframe)' do
    get path, headers: { 'Sec-Fetch-Dest' => 'iframe' }

    expect(response).to be_successful
    expect(response.body).not_to include('Woofed AI')
  end

  it 'restores the chrome on a top-level visit even if the session was embedded' do
    get path, headers: { 'Sec-Fetch-Dest' => 'iframe' } # become embedded
    get path, headers: { 'Sec-Fetch-Dest' => 'document' } # direct visit clears it

    expect(response).to be_successful
    expect(response.body).to include('Woofed AI')
  end
end
