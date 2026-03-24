require 'rails_helper'

RSpec.describe Users::JsonWebToken do
  let(:user) { create(:user) }

  describe '.encode_user' do
    it 'generates a token without expiration or audience by default (backwards compat)' do
      token = described_class.encode_user(user)
      result = described_class.decode_user(token)
      expect(result[:ok]).to eq(user)
    end
  end

  describe '.encode_embed' do
    it 'generates a token with exp and aud: embed claims' do
      token = described_class.encode_embed(user)
      result = described_class.decode_embed(token)
      expect(result[:ok]).to eq(user)
    end
  end

  describe '.decode_embed' do
    it 'decodes a valid token with expiration' do
      token = described_class.encode_embed(user)
      expect(described_class.decode_embed(token)[:ok]).to eq(user)
    end

    it 'returns error: :expired for an expired token' do
      token = travel_to(9.hours.ago) { described_class.encode_embed(user) }
      expect(described_class.decode_embed(token)[:error]).to eq(:expired)
    end

    it 'rejects a token without aud claim (API tokens)' do
      token = described_class.encode_user(user)
      expect(described_class.decode_embed(token)[:error]).to be_present
    end
  end
end
