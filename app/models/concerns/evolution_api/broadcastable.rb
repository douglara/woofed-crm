module EvolutionApi::Broadcastable
  extend ActiveSupport::Concern
  included do
    after_commit :broadcast_update_qrcode, if: -> { saved_change_to_qrcode? }

    after_update_commit do
      if saved_change_to_connection_status?(from: 'connecting', to: 'connected')
          broadcast_replace_later_to "qrcode_#{self.id}_#{self.account.id}", target: self, partial: '/components/redirect_page',
        locals: { path: Rails.application.routes.url_helpers.account_apps_evolution_apis_path(self.account) }
      end
      broadcast_replace_later_to "evolution_apis_#{account_id}", target: self, partial: '/accounts/apps/evolution_apis/evolution_api',
      locals: { evolution_api: self }
    end

    after_create_commit do
      broadcast_append_later_to "evolution_apis_#{account_id}", target: 'evolution_apis', partial: '/accounts/apps/evolution_apis/evolution_api',
      locals: { evolution_api: self }
    end

    def broadcast_update_qrcode
      broadcast_replace_later_to "qrcode_#{self.id}_#{self.account.id}", target: self, partial: 'accounts/apps/evolution_apis/qrcode',
                                                   locals: { evolution_api: self }
    end

  end
end
