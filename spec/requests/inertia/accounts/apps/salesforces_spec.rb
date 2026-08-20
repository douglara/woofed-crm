require 'rails_helper'
require 'inertia_rails/rspec'

RSpec.describe Inertia::Accounts::Apps::SalesforcesController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user) }
  let(:base_url) { "/accounts/#{account.id}/apps/salesforce" }
  let(:credentials) do
    { apps_salesforce: { name: 'Salesforce', environment: 'production', client_id: 'consumer-key',
                         client_secret: 'consumer-secret' } }
  end

  # What the screen sends while it refreshes itself: only the props whose values
  # a running sync changes.
  let(:progress_refresh_headers) do
    {
      'X-Inertia' => 'true',
      'X-Inertia-Version' => ViteRuby.digest,
      'X-Inertia-Partial-Component' => 'Apps/Salesforce/Show',
      'X-Inertia-Partial-Data' => 'sync_runs,problem_records,sync_in_progress,connection'
    }
  end

  describe 'GET /accounts/{account.id}/apps/salesforce' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get base_url

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before { sign_in(user) }

      context 'when no org was ever connected' do
        it 'renders the connect screen carrying the setup values to paste into salesforce' do
          get base_url

          expect(inertia).to render_component('Apps/Salesforce/Show')
          expect(inertia).to have_props(
            connection: nil,
            callback_url: apps_salesforces_oauth_callback_url,
            scopes: 'api refresh_token offline_access',
            object_mappings: []
          )
        end

        it 'offers every syncable object with the woofed fields its mapping can use' do
          get base_url

          expect(inertia.props[:syncable_objects].map { |object| object['salesforce_object'] })
            .to eq(%w[Account Contact Lead Opportunity Task Event])
          expect(inertia.props[:woofed_fields]['Company'].map { |field| field['name'] }).to include('name', 'email')
        end

        it 'includes the custom attributes an org field can be mapped onto' do
          create(:custom_attribute_definition, attribute_model: 'company_attribute',
                                               attribute_key: 'industria', attribute_display_name: 'Indústria')

          get base_url

          expect(inertia.props[:woofed_fields]['Company'])
            .to include('name' => 'industria', 'label' => 'Indústria', 'kind' => 'custom_attribute')
        end
      end

      # The credentials are saved before the user is sent to consent, so coming
      # back to the screen finds a row that has no org behind it yet.
      context 'when the credentials were saved but consent was never given' do
        let!(:salesforce) { create(:apps_salesforces) }

        it 'still renders the connect screen, with the standard objects' do
          get base_url

          expect(inertia).to render_component('Apps/Salesforce/Show')
          expect(inertia.props[:connection]).to include('connected' => false)
          expect(inertia.props[:syncable_objects].map { |object| object['salesforce_object'] })
            .to eq(%w[Account Contact Lead Opportunity Task Event])
        end
      end

      context 'when an org is connected' do
        let!(:salesforce) { create(:apps_salesforces, :connected) }

        # The object picker is fed by the org, so custom objects can be mapped too.
        before do
          stub_request(:get, 'https://woofed-dev-ed.my.salesforce.com/services/data/v64.0/sobjects')
            .to_return(
              status: 200,
              body: { 'sobjects' => [
                { 'name' => 'Account', 'label' => 'Account', 'queryable' => true, 'custom' => false },
                { 'name' => 'Escola__c', 'label' => 'Escola', 'queryable' => true, 'custom' => true },
                { 'name' => 'AcceptedEventRelation', 'label' => 'Hidden', 'queryable' => false,
                  'custom' => false }
              ] }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'offers the custom objects of the org alongside the standard ones' do
          get base_url

          expect(inertia.props[:syncable_objects]).to eq(
            [{ 'salesforce_object' => 'Account', 'label' => 'Account', 'custom' => false,
               'woofed_model' => 'Company' },
             { 'salesforce_object' => 'Escola__c', 'label' => 'Escola', 'custom' => true,
               'woofed_model' => nil }]
          )
        end

        it 'renders the connection and the mappings already saved' do
          create(:apps_salesforce_object_mappings, app: salesforce)

          get base_url

          expect(inertia.props[:connection]).to include(
            'status' => 'active', 'organization_id' => '00D5g000000XXXXEA0', 'connected' => true
          )
          expect(inertia.props[:object_mappings].first).to include(
            'salesforce_object' => 'Account', 'woofed_model' => 'Company', 'enabled' => true
          )
        end

        it 'lists the rows that did not make it, with the reason' do
          create(:apps_salesforce_raw_records, :conflict, app: salesforce)
          create(:apps_salesforce_raw_records, app: salesforce)

          get base_url

          expect(inertia.props[:problem_records]).to eq(
            [{ 'id' => Apps::Salesforce::RawRecord.first.id, 'salesforce_object' => 'Account',
               'salesforce_id' => '001Hn00001AbCdEIAV', 'status' => 'conflict',
               'error' => 'Email already belongs to another contact' }]
          )
        end

        it 'shows the latest run of each object, which is the sync progress' do
          create(:apps_salesforce_sync_runs, app: salesforce, salesforce_object: 'Account',
                                             status: 'completed', records_downloaded: 1_200)

          get base_url

          expect(inertia.props[:sync_runs].first).to include(
            'salesforce_object' => 'Account', 'status' => 'completed', 'records_downloaded' => 1_200
          )
        end

        # The screen refreshes itself on its own while this is true, so it has to
        # stay true for as long as the numbers on it can still change.
        it 'reports the sync as in progress while a run has not finished' do
          create(:apps_salesforce_sync_runs, :running, app: salesforce)

          get base_url

          expect(inertia.props[:sync_in_progress]).to be(true)
        end

        it 'keeps reporting progress while downloaded rows are still being loaded' do
          create(:apps_salesforce_sync_runs, app: salesforce, status: 'completed')
          create(:apps_salesforce_raw_records, app: salesforce)

          get base_url

          expect(inertia.props[:sync_in_progress]).to be(true)
        end

        it 'stops reporting progress once every run finished and every row was loaded' do
          create(:apps_salesforce_sync_runs, app: salesforce, status: 'completed')
          create(:apps_salesforce_raw_records, :processed, app: salesforce)

          get base_url

          expect(inertia.props[:sync_in_progress]).to be(false)
        end

        # One of these lands every few seconds while a sync runs. Reading the
        # object list on each of them would spend the org's API allocation on a
        # list the screen already has.
        it 'answers a progress refresh with the progress alone, without reading the org again' do
          create(:apps_salesforce_sync_runs, :running, app: salesforce, records_downloaded: 40)

          get base_url, headers: progress_refresh_headers

          expect(inertia.props.keys).not_to include('syncable_objects', 'woofed_fields', 'object_mappings')
          expect(inertia.props[:sync_runs].first).to include(
            'status' => 'running', 'records_downloaded' => 40
          )
          expect(
            a_request(:get, 'https://woofed-dev-ed.my.salesforce.com/services/data/v64.0/sobjects')
          ).not_to have_been_made
        end
      end
    end
  end

  describe 'POST /accounts/{account.id}/apps/salesforce' do
    before { sign_in(user) }

    context 'when the credentials are filled in' do
      # Consent lives on another host, which the page cannot reach by following a
      # redirect from its own XHR: it has to be told to leave.
      it 'stores them and sends the user to the salesforce consent screen with PKCE' do
        expect { post base_url, params: credentials }.to change(Apps::Salesforce, :count).by(1)

        redirect = URI.parse(response.headers['X-Inertia-Location'])
        query = Rack::Utils.parse_query(redirect.query)

        expect(response).to have_http_status(:conflict)
        expect("#{redirect.scheme}://#{redirect.host}#{redirect.path}")
          .to eq('https://login.salesforce.com/services/oauth2/authorize')
        expect(query).to include(
          'response_type' => 'code',
          'client_id' => 'consumer-key',
          'scope' => 'api refresh_token offline_access',
          'code_challenge_method' => 'S256',
          'redirect_uri' => apps_salesforces_oauth_callback_url
        )
        expect(query['code_challenge']).to be_present
      end
    end

    context 'when the org is a sandbox' do
      it 'authenticates against the test login host' do
        post base_url, params: credentials.deep_merge(apps_salesforce: { environment: 'sandbox' })

        expect(response.headers['X-Inertia-Location'])
          .to start_with('https://test.salesforce.com/services/oauth2/authorize')
      end
    end

    context 'when a connection already exists' do
      it 'reconnects by editing it instead of creating a second one' do
        create(:apps_salesforces, client_id: 'old-consumer-key')

        expect { post base_url, params: credentials }.not_to change(Apps::Salesforce, :count)
        expect(Apps::Salesforce.first.client_id).to eq('consumer-key')
      end
    end

    context 'when the credentials are blank' do
      it 'redirects back with the error and stores nothing' do
        post base_url, params: { apps_salesforce: { client_id: '', client_secret: '' } }

        expect(response).to redirect_to(base_url)
        expect(flash[:alert]).to be_present
        expect(Apps::Salesforce.count).to eq(0)
      end
    end
  end

  describe 'DELETE /accounts/{account.id}/apps/salesforce' do
    before { sign_in(user) }

    context 'when a connection exists' do
      it 'revokes the refresh token and removes it' do
        create(:apps_salesforces, :connected)
        revoke_url = 'https://woofed-dev-ed.my.salesforce.com/services/oauth2/revoke'
        stub_request(:post, revoke_url).to_return(status: 200)

        delete base_url

        expect(a_request(:post, revoke_url)).to have_been_made
        expect(Apps::Salesforce.count).to eq(0)
        expect(flash[:notice]).to eq(I18n.t('apps.salesforce.disconnected'))
      end
    end

    context 'when there is no connection' do
      it 'redirects back without failing' do
        delete base_url

        expect(response).to redirect_to(base_url)
      end
    end
  end

  describe 'POST /accounts/{account.id}/apps/salesforce/sync' do
    before { sign_in(user) }

    context 'when an object is enabled' do
      it 'queues the initial load and says so' do
        salesforce = create(:apps_salesforces, :connected)
        create(:apps_salesforce_object_mappings, app: salesforce)
        stub_request(:get, %r{/services/data/v64.0/(sobjects|query)})
          .to_return(status: 200, body: { 'sobjects' => [], 'totalSize' => 0, 'done' => true,
                                          'records' => [] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        post "#{base_url}/sync"

        expect(salesforce.sync_runs.pluck(:salesforce_object)).to eq(['Account'])
        expect(flash[:notice]).to eq(I18n.t('apps.salesforce.backfill.started'))
      end
    end

    context 'when no org is connected' do
      it 'reports it instead of queueing work that cannot run' do
        post "#{base_url}/sync"

        expect(Apps::Salesforce::SyncRun.count).to eq(0)
        expect(flash[:alert]).to eq(I18n.t('apps.salesforce.missing_connection'))
      end
    end
  end

  describe 'GET /accounts/{account.id}/apps/salesforce/describe/{object}' do
    before { sign_in(user) }

    let(:describe_url) do
      'https://woofed-dev-ed.my.salesforce.com/services/data/v64.0/sobjects/Account/describe'
    end

    context 'when the org answers' do
      it 'returns the fields the pickers need, without the rest of the payload' do
        create(:apps_salesforces, :connected)
        stub_request(:get, describe_url).to_return(
          status: 200,
          body: { 'name' => 'Account', 'fields' => [
            { 'name' => 'Industria__c', 'label' => 'Indústria', 'type' => 'picklist', 'custom' => true,
              'picklistValues' => [{ 'value' => 'Varejo' }] }
          ] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        get "#{base_url}/describe/Account"

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['fields']).to eq(
          [{ 'name' => 'Industria__c', 'label' => 'Indústria', 'type' => 'picklist', 'custom' => true }]
        )
      end
    end

    context 'when the org refuses' do
      it 'passes the reason on so the card can show it' do
        create(:apps_salesforces, :connected)
        stub_request(:get, describe_url).to_return(
          status: 400, body: [{ message: 'The requested resource does not exist' }].to_json
        )

        get "#{base_url}/describe/Account"

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('The requested resource does not exist')
      end
    end

    context 'when no org is connected' do
      it 'says so instead of calling salesforce' do
        get "#{base_url}/describe/Account"

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq(I18n.t('apps.salesforce.missing_connection'))
      end
    end
  end
end
