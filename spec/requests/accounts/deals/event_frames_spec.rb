require 'rails_helper'

# Regression: the deal page loads its scheduled ("to do") and completed ("done")
# event lists through lazy turbo-frames. The frame's initial request must be
# answered with the matching <turbo-frame> HTML so it REPLACES the skeleton
# placeholder. If it is answered with a turbo_stream (append), the skeletons are
# never removed and real events stack underneath them. Browsers send
# `Accept: */*` for these frames, so HTML must win content negotiation; the
# turbo_stream (append) response is reserved for explicit `.turbo_stream`
# pagination requests.
RSpec.describe 'Deal event frames', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:pipeline) { create(:pipeline) }
  let!(:stage) { create(:stage, pipeline:) }
  let!(:contact) { create(:contact) }
  let!(:deal) { create(:deal, contact:, stage:, pipeline:) }
  let(:frame_id) { "events_to_do_#{contact.id}" }

  before { sign_in(user) }

  it 'replaces the skeleton: answers the lazy frame with a turbo-frame, not a turbo_stream' do
    get events_to_do_account_deal_path(account, deal),
        headers: { 'Accept' => '*/*', 'Turbo-Frame' => frame_id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(turbo-frame id="#{frame_id}"))
    expect(response.body).not_to include(%(turbo-stream action="append" target="#{frame_id}"))
  end

  it 'appends the next page only when turbo_stream is requested explicitly' do
    get events_to_do_account_deal_path(account, deal, format: :turbo_stream)

    expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    expect(response.body).to include(%(turbo-stream action="append" target="#{frame_id}"))
  end
end
