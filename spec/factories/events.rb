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
FactoryBot.define do
  factory :event do
    contact
    deal
    title { 'Event 1' }
    content { 'Hi Lorena' }
    kind { 'activity' }

    trait :with_file do
      after(:build) do |event|
        attachment = event.build_attachment
        attachment.file.attach(
          io: Rails.root.join('spec/fixtures/files/patrick.png').open,
          filename: 'patrick.png',
          content_type: 'image/png'
        )
        attachment.file_type = attachment.check_file_type
      end
    end
    trait :with_audio do
      after(:build) do |event|
        attachment = event.build_attachment
        attachment.file.attach(
          io: Rails.root.join('spec/fixtures/files/audio_test.oga').open,
          filename: 'audio_test.oga',
          content_type: 'audio/oga'
        )
        attachment.file_type = attachment.check_file_type
      end
    end
    trait :with_zip_file do
      after(:build) do |event|
        attachment = event.build_attachment
        attachment.file.attach(
          io: Rails.root.join('spec/fixtures/files/hello_world.rar').open,
          filename: 'hello_world.rar',
          content_type: 'application/x-rar-compressed;version=5'
        )
        attachment.file_type = attachment.check_file_type
      end
    end
  end
end
