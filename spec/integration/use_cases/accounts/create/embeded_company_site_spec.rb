# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accounts::Create::EmbededCompanySite, type: :request do
  describe 'success' do
    subject { described_class.new(account) }

    let(:account) { create(:account, site_url: 'https://docs.woofedcrm.com/docs/intro') }
    let!(:ai_assistent) { create(:apps_ai_assistent, auto_reply: true) }
    let(:embedding_documment_imported) { EmbeddingDocumment.find_by(source_reference: account.site_url) }

    it 'embeded company site' do
      stub_request(:get, 'https://docs.woofedcrm.com/docs/intro')
        .to_return(status: 200, body: File.read('spec/integration/use_cases/accounts/create/mock_docs_site/intro.html'))
      stub_request(:get, 'https://docs.woofedcrm.com/docs/%23__docusaurus_skipToContent_fallback')
        .to_return(status: 200, body: File.read('spec/integration/use_cases/accounts/create/mock_docs_site/23__docusaurus_skipToContent_fallback.html'))
      stub_request(:get, 'https://docs.woofedcrm.com/docs/Developer%20Guides/Self%20hosted/deploy')
        .to_return(status: 200, body: File.read('spec/integration/use_cases/accounts/create/mock_docs_site/deploy.html'))
      stub_request(:post, /embeddings/)
        .to_return(status: 200, body: File.read('spec/integration/use_cases/accounts/create/mock_docs_site/intro_embedding.json'))

      result = subject.call(3)
      expect(EmbeddingDocumment.count).to eq(3)
      expect(embedding_documment_imported.embedding.present?).to be true
    end
  end
end
