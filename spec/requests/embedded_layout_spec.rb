require 'rails_helper'

# The Chatwoot widget embeds WoofedCRM pages in an iframe and must drop the app
# chrome (sidebar + navbar) so it feels native to Chatwoot. That decision is made
# CLIENT-SIDE per browsing context (window.self !== window.top) — see
# layouts/internal.html.erb — so the chrome is always rendered server-side and
# hidden by CSS only when framed. This avoids the embedded state leaking between
# an iframe and a direct browser tab that share the same session.
# "Woofed AI" is a sidebar menu label, used here as a chrome marker.
RSpec.describe 'Embedded chrome-less rendering', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let(:path) { account_contacts_path(account) }

  before { sign_in user }

  it 'always renders the chrome server-side (regardless of how it is loaded)' do
    get path
    expect(response).to be_successful
    expect(response.body).to include('Woofed AI')

    # Same for an iframe-style request: the server no longer hides chrome — the
    # client does, so the markup is identical.
    get path, headers: { 'Sec-Fetch-Dest' => 'iframe' }
    expect(response.body).to include('Woofed AI')
  end

  it 'ships the client-side iframe-detection that hides the chrome when framed' do
    get path

    expect(response.body).to include('woofed-embedded') # the hide hook
    expect(response.body).to include('window.self !== window.top') # iframe detection
    expect(response.body).to include('woofed-chrome') # the wrapped, hideable chrome
  end
end
