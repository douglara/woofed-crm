require 'rails_helper'

RSpec.describe Webhook do
  let!(:account) { create(:account) }

  describe 'validations' do
    context 'validate_webhook_url' do
      context 'valid' do
        context 'when status is active' do
          before do
            allow_any_instance_of(Webhook).to receive(:valid_url?).and_return(true)
          end

          it do
            new_webhook = build(:webhook, url: 'https://www.webhook.com', status: :active)
            expect(new_webhook).to be_valid
          end
        end
        context 'when status is inactive' do
          it do
            new_webhook = build(:webhook, url: 'https://www.webhook.com', status: :inactive)
            expect(new_webhook).not_to receive(:validate_webhook_url)
            expect(new_webhook).to be_valid
          end
        end
      end
      context 'invalid' do
        context 'when url response request is invalid' do
          before do
            allow_any_instance_of(Webhook).to receive(:valid_url?).and_return(false)
          end
          it do
            new_webhook = build(:webhook, url: 'https://www.webhook.com', status: :active)
            expect(new_webhook).to be_invalid
            expect(new_webhook.errors[:url]).to include('is invalid')
          end
        end
        context 'when url format is invalid' do
          before do
            allow_any_instance_of(Webhook).to receive(:valid_url?).and_return(true)
          end
          it do
            new_webhook = build(:webhook, url: 'www.webhook.com', status: :active)
            expect(new_webhook).to be_invalid
            expect(new_webhook.errors[:url]).to include('is invalid')
          end
        end
        context 'when url is blank' do
          before do
            allow_any_instance_of(Webhook).to receive(:valid_url?).and_return(true)
          end
          it do
            new_webhook = build(:webhook, url: '', status: :active)
            expect(new_webhook).to be_invalid
            expect(new_webhook.errors[:url]).to include('is invalid')
          end
        end
      end
    end
    context 'validates status' do
      before do
        allow_any_instance_of(Webhook).to receive(:valid_url?).and_return(true)
      end

      context 'valid' do
        it 'when status is active' do
          new_webhook = build(:webhook, url: 'https://www.webhook.com', status: :active)
          expect(new_webhook).to be_valid
        end
        it 'when status is inactive' do
          new_webhook = build(:webhook, url: 'https://www.webhook.com', status: :inactive)
          expect(new_webhook).to be_valid
        end
      end
      context 'invalid' do
        context 'when status is blank' do
          it do
            new_webhook = build(:webhook, url: 'https://www.webhook.com', status: '')
            expect(new_webhook).to be_invalid
            expect(new_webhook.errors[:status]).to include(/can't be blank/)
          end
        end
        context 'when status invalid' do
          it do
            expect do
              build(:webhook, url: 'www.webhook.com', status: 'status_test_123456')
            end.to raise_error(ArgumentError, "'status_test_123456' is not a valid status")
          end
        end
      end
    end
  end

  describe '#valid_url?' do
    let(:webhook) do
      create(:webhook, :skip_validate)
    end

    context 'when is valid' do
      before do
        stub_request(:post, webhook.url)
          .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it do
        expect(webhook.valid_url?).to be true
      end
    end

    context 'when is invalid' do
      context 'when http reponse status is different than 200' do
        before do
          stub_request(:post, webhook.url)
            .to_return(status: 504, body: 'Bad gateway')
        end

        it do
          expect(webhook.valid_url?).to be false
        end
      end
      context 'when request fails' do
        context 'timeout error' do
          before do
            api_client_double = instance_double(Webhook::ApiClient)
            allow(Webhook::ApiClient).to receive(:new).and_return(api_client_double)
            allow(api_client_double).to receive(:post_request).and_raise(Faraday::TimeoutError)
          end
          it do
            expect(webhook.valid_url?).to be false
          end
        end
        context 'timeout error' do
          before do
            api_client_double = instance_double(Webhook::ApiClient)
            allow(Webhook::ApiClient).to receive(:new).and_return(api_client_double)
            allow(api_client_double).to receive(:post_request).and_raise(Faraday::ConnectionFailed)
          end
          it do
            expect(webhook.valid_url?).to be false
          end
        end
      end
      context 'when url is blank' do
        let(:webhook) do
          create(:webhook, :skip_validate, url: '')
        end

        it do
          expect(webhook.valid_url?).to be false
        end
      end
    end
  end
end
