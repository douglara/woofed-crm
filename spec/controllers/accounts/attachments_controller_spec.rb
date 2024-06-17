require 'rails_helper'

RSpec.describe Accounts::AttachmentsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:attachment) { create(:attachment, :for_product, :image) }

  describe 'DELETE /accounts/{account.id}/attachments/{attachment.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/attachments/#{attachment.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'delete attachemnt' do
        it do
          delete "/accounts/#{account.id}/attachments/#{attachment.id}",
                 headers: { 'ACCEPT' => 'text/vnd.turbo-stream.html' }
          expect(Attachment.count).to eq(0)
          expect(response).to have_http_status(200)
        end
      end
    end
  end
end
