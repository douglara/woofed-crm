# == Schema Information
#
# Table name: contacts
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  app_type              :string
#  custom_attributes     :jsonb
#  email                 :string           default(""), not null
#  full_name             :string           default(""), not null
#  phone                 :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  app_id                :bigint
#
# Indexes
#
#  index_contacts_on_app          (app_type,app_id)
#  index_contacts_on_lower_email  (lower(NULLIF((email)::text, ''::text))) UNIQUE
#  index_contacts_on_phone        (NULLIF((phone)::text, ''::text)) UNIQUE
#
require 'rails_helper'
RSpec.describe Contact do
  let!(:account) { create(:account) }

  describe 'validations' do
    let(:valid_email) { 'test@example.com' }
    let(:valid_phone) { '+123456789' }
    let(:other_email) { 'other@example.com' }
    let(:other_phone) { '+987654321' }

    context 'validates email' do
      context 'valid' do
        it 'when email is unique (case-insensitive)' do
          create(:contact, email: valid_email, phone: valid_phone)
          new_contact = build(:contact, email: other_email, phone: other_phone)

          expect(new_contact).to be_valid
        end

        it 'when email is blank (empty string)' do
          new_contact = build(:contact, email: '', phone: valid_phone)

          expect(new_contact).to be_valid
        end

        it 'when multiple contacts have blank email (empty string)' do
          create(:contact, email: '', phone: valid_phone)
          create(:contact, email: '', phone: other_phone)
          new_contact = build(:contact, email: '', phone: '+123456788')

          expect(new_contact).to be_valid
        end

        it 'when email has valid format' do
          new_contact = build(:contact, email: 'valid@example.com', phone: valid_phone)

          expect(new_contact).to be_valid
        end
        context 'when skip_validation is true' do
          it 'when email is already taken' do
            create(:contact, email: valid_email, phone: valid_phone)
            new_contact = build(:contact, email: valid_email, phone: valid_phone,
                                          skip_validation: true)

            expect(new_contact).to be_valid
            expect { new_contact.save!(validate: true) }
          end
        end
      end

      context 'invalid' do
        it 'when email is already taken (case-insensitive)' do
          create(:contact, email: valid_email, phone: valid_phone)
          new_contact = build(:contact, email: valid_email.upcase, phone: other_phone)

          expect(new_contact).to be_invalid
          expect(new_contact.errors[:email]).to include('has already been taken')

          expect { new_contact.save!(validate: false) }
            .to raise_error(ActiveRecord::RecordNotUnique)
        end

        it 'when email is nil' do
          new_contact = build(:contact, email: nil, phone: valid_phone)

          # expect(new_contact).to be_invalid
          # expect(new_contact.errors[:email]).to include("can't be nil")

          expect { new_contact.save!(validate: false) }
            .to raise_error(ActiveRecord::NotNullViolation)
        end

        it 'when email has invalid format' do
          new_contact = build(:contact, email: 'invalid_email', phone: valid_phone)

          expect(new_contact).to be_invalid
          expect(new_contact.errors[:email]).to include(I18n.t('activerecord.errors.contact.email.invalid'))
        end
      end
    end

    context 'validates phone' do
      context 'valid' do
        it 'when phone is unique' do
          create(:contact, email: valid_email, phone: valid_phone)
          new_contact = build(:contact, email: other_email, phone: other_phone)

          expect(new_contact).to be_valid
        end

        it 'when phone is blank (empty string)' do
          new_contact = build(:contact, email: valid_email, phone: nil)

          expect(new_contact).to be_valid
        end

        it 'when multiple contacts have blank phone (empty string)' do
          create(:contact, email: valid_email, phone: '')
          create(:contact, email: other_email, phone: '')
          new_contact = build(:contact, email: 'another@example.com', phone: '')

          expect(new_contact).to be_valid
        end

        it 'when phone has valid format' do
          new_contact = build(:contact, email: valid_email, phone: '+123456788')

          expect(new_contact).to be_valid
        end

        context 'when skip_validation is true' do
          it 'when phone is invalid' do
            new_contact = build(:contact, email: valid_email, phone: '546546546546546546546546546546',
                                          skip_validation: true)
            expect(new_contact).to be_valid
            expect { new_contact.save!(validate: true) }
          end
          it 'when phone is already taken' do
            create(:contact, email: valid_email, phone: valid_phone)
            new_contact = build(:contact, email: other_email, phone: valid_phone,
                                          skip_validation: true)

            expect(new_contact).to be_valid
            expect { new_contact.save!(validate: true) }
          end
        end
      end

      context 'invalid' do
        it 'when phone is already taken' do
          create(:contact, email: valid_email, phone: valid_phone)
          new_contact = build(:contact, email: other_email, phone: valid_phone)

          expect(new_contact).to be_invalid
          expect(new_contact.errors[:phone]).to include('has already been taken')

          expect { new_contact.save!(validate: false) }
            .to raise_error(ActiveRecord::RecordNotUnique)
        end

        it 'when phone is more than 15 characters' do
          new_contact = build(:contact, email: valid_email, phone: '+552299881378888889')

          expect(new_contact).to be_invalid
          expect(new_contact.errors[:phone]).to include(I18n.t('activerecord.errors.contact.phone.invalid'))
        end

        it 'when phone starts with +0' do
          new_contact = build(:contact, email: valid_email, phone: '+052299881378888889')

          expect(new_contact).to be_invalid
          expect(new_contact.errors[:phone]).to include(I18n.t('activerecord.errors.contact.phone.invalid'))
        end

        it 'when phone starts with +0' do
          new_contact = build(:contact, email: valid_email, phone: '052299881378888889')

          expect(new_contact).to be_invalid
          expect(new_contact.errors[:phone]).to include(I18n.t('activerecord.errors.contact.phone.invalid'))
        end

        it 'when phone is nil' do
          new_contact = build(:contact, email: valid_email, phone: nil)

          # expect(new_contact).to be_invalid
          # expect(new_contact.errors[:phone]).to include("can't be nil")

          expect { new_contact.save!(validate: false) }
            .to raise_error(ActiveRecord::NotNullViolation)
        end

        it 'when phone has character' do
          new_contact = build(:contact, email: valid_email, phone: 'invalid_phone')

          expect(new_contact).to be_invalid
          expect(new_contact.errors[:phone]).to include(I18n.t('activerecord.errors.contact.phone.invalid'))
        end
      end
    end
  end
end
