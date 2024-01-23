# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  app_type              :string
#  auto_done             :boolean          default(FALSE)
#  custom_attributes     :jsonb
#  done_at               :datetime
#  from_me               :boolean
#  kind                  :string           not null
#  scheduled_at          :datetime
#  status                :integer
#  title                 :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  app_id                :bigint
#  contact_id            :bigint
#  deal_id               :bigint
#
# Indexes
#
#  index_events_on_account_id  (account_id)
#  index_events_on_app         (app_type,app_id)
#  index_events_on_contact_id  (contact_id)
#  index_events_on_deal_id     (deal_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
require 'rails_helper'

RSpec.describe Event do
  context 'scopes' do
    let(:account) { create(:account) }
    let!(:event_done) { create(:event, done: true, kind: 'note', account: account) }
    let!(:event_planned_1) do
      create(:event, account: account, auto_done: false, scheduled_at: (Time.current + 1.hour), kind: 'activity')
    end
    let!(:event_planned_2) do
      create(:event, account: account, auto_done: false, scheduled_at: (Time.current + 2.hour), kind: 'activity')
    end
    let!(:event_scheduled_1) do
      create(:event, account: account, auto_done: true, scheduled_at: (Time.current + 2.hour), kind: 'activity')
    end

    describe 'planned' do
      it 'returns 2 events' do
        expect(account.events.planned.count).to be 2
      end
    end

    skip 'planned overdue' do
    end

    skip 'planned without date' do
    end

    describe 'scheduled' do
      it 'returns 1 events' do
        expect(account.events.scheduled.count).to be 1
      end
    end
  end
end
