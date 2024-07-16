module Contact::Broadcastable
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  included do
    after_create_commit do
    end
    after_update_commit do
      deals.find_each do |deal|
        broadcast_replace_later_to deal, target: self, partial: 'accounts/deals/details/show',
                                         locals: { model: self, edit_path: edit_account_contact_path(account, self, deal_page_id: deal.id) }
      end
    end
  end
end
