# frozen_string_literal: true

# == Schema Information
#
# Table name: apps_ai_assistents
#
#  id         :bigint           not null, primary key
#  api_key    :string           default(""), not null
#  auto_reply :boolean          default(FALSE), not null
#  enabled    :boolean          default(FALSE), not null
#  model      :string           default("gpt-4o"), not null
#  usage      :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Apps::AiAssistent < ApplicationRecord
  validates :model, presence: true
  validates :api_key, presence: true, if: :enabled?

  after_update :embed_company_site, if: -> { saved_change_to_enabled? || saved_change_to_api_key? }
  # The Python agent (ai-agent/) listens for this NOTIFY on the
  # `ai_assistent_changed` channel and restarts itself so it picks up the new
  # model/api_key without a manual reload. Fires on create, update and destroy.
  # See ai-agent/db_listener.py.
  after_commit :notify_agent_restart

  def notify_agent_restart
    self.class.connection.execute('NOTIFY ai_assistent_changed')
  end

  def embed_company_site
    Accounts::Create::EmbedCompanySiteJob.perform_later(id) if Current.account.site_url.present? && enabled?
  end

  def exceeded_usage_limit?
    return false if usage['limit'].blank?

    usage['tokens'] >= usage['limit']
  end
end
