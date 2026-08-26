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
#  app_id                :bigint
#  contact_id            :bigint
#  deal_id               :bigint
#
# Indexes
#
#  index_events_on_app         (app_type,app_id)
#  index_events_on_contact_id  (contact_id)
#  index_events_on_deal_id     (deal_id)
#
require 'rails_helper'

RSpec.describe Event do
  context 'scopes' do
    let(:account) { create(:account) }
    let!(:event_done) { create(:event, done: true, scheduled_at: Time.current, kind: 'note', deal: nil, account:) }
    let!(:event_planned_1) do
      create(:event, account:, auto_done: false, scheduled_at: (Time.current + 1.hour), kind: 'activity', deal: nil)
    end
    let!(:event_planned_2) do
      create(:event, account:, auto_done: false, scheduled_at: (Time.current + 2.hour), kind: 'activity', deal: nil)
    end
    let!(:event_scheduled_1) do
      create(:event, account:, auto_done: true, scheduled_at: (Time.current + 2.hour), kind: 'activity', deal: nil)
    end
    let!(:event_planned_overdue_1) do
      create(:event, account:, auto_done: false, scheduled_at: (Time.current - 2.hour), kind: 'activity', deal: nil)
    end
    let!(:event_planned_overdue_2) do
      create(:event, account:, auto_done: false, scheduled_at: (Time.current - 1.hour), kind: 'activity', deal: nil)
    end
    let!(:event_planned_overdue_3) do
      create(:event, account:, auto_done: false, scheduled_at: (Time.current - 1.hour), kind: 'activity', deal: nil)
    end
    let!(:event_planned_without_date_1) do
      create(:event, account:, auto_done: false, scheduled_at: nil, kind: 'activity', deal: nil)
    end
    let!(:event_planned_without_date_2) do
      create(:event, account:, auto_done: false, scheduled_at: nil, kind: 'activity', deal: nil)
    end
    let!(:event_wpp_message) do
      create(:event, account:, done: true, additional_attributes: { message_id: 'id' }, scheduled_at: nil,
                     kind: 'evolution_api_message', deal: nil)
    end
    describe 'done' do
      it 'returns 2 event' do
        expect(account.events.done.count).to be 2
      end
    end

    describe 'planned' do
      it 'returns 5 events' do
        expect(account.events.planned.count).to be 5
      end
    end

    describe 'planned overdue' do
      it 'returns 3 events' do
        expect(account.events.planned_overdue.count).to be 3
      end
    end

    describe 'planned without date' do
      it 'returns 2 events' do
        expect(account.events.planned_without_date.count).to be 2
      end
    end
    describe 'to do' do
      it 'returns 8 events' do
        expect(account.events.to_do.count).to be 8
      end
    end

    describe 'scheduled' do
      it 'returns 1 events' do
        expect(account.events.scheduled.count).to be 1
      end
    end

    describe 'by_message_id' do
      it 'returns 1 events' do
        expect(account.events.by_message_id('id').count).to be 1
      end
    end
  end
  context 'generate_content_hash' do
    context 'when is chatwoot_message event' do
      let(:account) { create(:account) }
      let!(:event_content_blank) do
        create(:event, done: true, scheduled_at: Time.current, kind: 'chatwoot_message', account:, content: '')
      end
      let!(:event) do
        create(:event, done: true, scheduled_at: Time.current, kind: 'chatwoot_message', account:,
                       content: 'Hello world!')
      end
      it 'should return with contents blank' do
        expect(event.generate_content_hash('content', event_content_blank.content)).to eq('content' => '')
      end
      it 'should generate hash and content should not be blank' do
        expect(event.generate_content_hash('content',
                                           event.content)).to eq('content' => 'Hello world!')
      end
    end
  end
  context 'chatwoot whatsapp template' do
    let(:account) { create(:account) }
    let(:inbox) { JSON.parse(File.read('spec/integration/use_cases/accounts/apps/chatwoots/inbox_detail.json')) }
    let(:chatwoot) { create(:apps_chatwoots, :skip_validate, account:, inboxes: [inbox]) }
    let(:contact) { create(:contact, account:) }

    def template_event(attributes)
      build(:event, kind: 'chatwoot_message', from_me: true, app: chatwoot, contact:, deal: nil,
                    additional_attributes: attributes)
    end

    it 'resolves the definition, content and params of a body-only template' do
      event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'lembrete_aula',
                             'template_body_params' => { '1' => 'Paula', '2' => '14:00' })

      expect(event.chatwoot_template?).to be true
      expect(event.chatwoot_template_definition['name']).to eq('lembrete_aula')
      expect(event.resolved_template_content).to eq('Oi Paula! Sua aula experimental e hoje as 14:00!')
      expect(event.chatwoot_template_params).to eq(
        'name' => 'lembrete_aula', 'category' => 'UTILITY', 'language' => 'pt_BR',
        'processed_params' => { 'body' => { '1' => 'Paula', '2' => '14:00' } }
      )
    end

    it 'ignores a static TEXT header (no header in processed params)' do
      event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'appointment_confirmation',
                             'template_body_params' => { '1' => 'John', '2' => '05/06/26', '3' => '10:00h' })

      expect(event.chatwoot_template_params['processed_params']).to eq('body' => { '1' => 'John', '2' => '05/06/26',
                                                                                   '3' => '10:00h' })
    end

    it 'includes media header for a media-header template' do
      event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'flight_confirmation',
                             'template_body_params' => { '1' => 'Recife' },
                             'template_header_media_url' => 'https://files.example/ticket.pdf')

      expect(event.chatwoot_template_params['processed_params']).to eq(
        'body' => { '1' => 'Recife' },
        'header' => { 'media_url' => 'https://files.example/ticket.pdf', 'media_type' => 'document' }
      )
    end

    it 'sends only dynamic URL buttons in processed params' do
      event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'validation_code',
                             'template_body_params' => { '1' => '123456' },
                             'template_button_params' => { '0' => '123456' })

      expect(event.chatwoot_template_params['processed_params']).to eq(
        'body' => { '1' => '123456' },
        'buttons' => [{ 'type' => 'url', 'parameter' => '123456' }]
      )
    end

    it 'stores the resolved template text as content on save so it shows in the CRM timeline' do
      event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'lembrete_aula',
                             'template_body_params' => { '1' => 'Paula', '2' => '14:00' })
      event.save!
      expect(event.reload.content.to_s).to eq('Oi Paula! Sua aula experimental e hoje as 14:00!')
    end

    it 'falls back to plain content when the chosen template no longer exists' do
      event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'ghost')
      event.content = 'plain fallback'

      expect(event.chatwoot_template_definition).to be_nil
      expect(event.chatwoot_template_params).to be_nil
      expect(event.resolved_template_content).to eq('plain fallback')
    end

    context 'validation' do
      it 'is valid as free text on a whatsapp inbox (no template selected)' do
        event = build(:event, kind: 'chatwoot_message', from_me: true, app: chatwoot, contact:, deal: nil,
                              content: 'oi', additional_attributes: { 'chatwoot_inbox_id' => 101 })
        expect(event).to be_valid
      end

      it 'is invalid when a required body variable is missing' do
        event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'lembrete_aula',
                               'template_body_params' => { '1' => 'Paula' })
        expect(event).to be_invalid
        expect(event.errors[:base])
          .to include(I18n.t('activerecord.errors.models.event.attributes.base.chatwoot_template_body_params_missing'))
      end

      it 'is invalid when a media header url is missing' do
        event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'flight_confirmation',
                               'template_body_params' => { '1' => 'Recife' })
        expect(event).to be_invalid
        expect(event.errors[:base])
          .to include(I18n.t('activerecord.errors.models.event.attributes.base.chatwoot_template_header_missing'))
      end

      it 'is invalid when the chosen template is not found' do
        event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'ghost')
        expect(event).to be_invalid
        expect(event.errors[:base])
          .to include(I18n.t('activerecord.errors.models.event.attributes.base.chatwoot_template_not_found'))
      end
    end

    context 'merge tags (per-lead variables)' do
      let(:contact) { create(:contact, account:, full_name: 'Lorena') }

      it 'resolves a {{contact.field}} body variable to this lead value' do
        event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'lembrete_aula',
                               'template_body_params' => { '1' => '{{contact.full_name}}', '2' => '14:00' })

        expect(event.resolved_template_content).to eq('Oi Lorena! Sua aula experimental e hoje as 14:00!')
        expect(event.chatwoot_template_params['processed_params']['body']).to eq('1' => 'Lorena', '2' => '14:00')
        expect(event.chatwoot_template_missing_data?).to be false
      end

      it 'resolves a custom-attribute merge tag' do
        contact.update!(custom_attributes: { 'codigo' => 'ABC123' })
        event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'lembrete_aula',
                               'template_body_params' => { '1' => '{{contact.full_name}}', '2' => '{{contact.custom.codigo}}' })

        expect(event.chatwoot_template_params['processed_params']['body']).to eq('1' => 'Lorena', '2' => 'ABC123')
      end

      it 'reports missing data when a mapped field has no value for the lead' do
        event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'lembrete_aula',
                               'template_body_params' => { '1' => '{{contact.custom.codigo}}', '2' => '14:00' })

        expect(event.chatwoot_template_missing_data?).to be true
      end

      it 'treats a blank fixed-text value as a config error, not a per-lead skip' do
        event = template_event('chatwoot_inbox_id' => 101, 'chatwoot_template_name' => 'lembrete_aula',
                               'template_body_params' => { '1' => '', '2' => '14:00' })

        expect(event.chatwoot_template_missing_data?).to be false
        expect(event).to be_invalid
      end
    end
  end

  context 'editable?' do
    let(:account) { create(:account) }
    let!(:event_done) { create(:event, done: true, scheduled_at: Time.current, kind: 'note', account:) }
    let!(:event_activity) do
      create(:event, account:, auto_done: false, scheduled_at: (Time.current + 1.hour), kind: 'activity')
    end
    let!(:event_chatwoot_message) do
      create(:event, account:, auto_done: false, scheduled_at: (Time.current + 2.hour),
                     kind: 'chatwoot_message')
    end
    let!(:event_chatwoot_message_done) do
      create(:event, account:, done: true, kind: 'chatwoot_message')
    end
    let(:events_editable) { Event.all.select(&:editable?) }
    it 'should return 3 events' do
      expect(events_editable.count).to be 3
    end
  end
end
