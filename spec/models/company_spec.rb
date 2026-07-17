# == Schema Information
#
# Table name: companies
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  custom_attributes     :jsonb
#  email                 :string           default(""), not null
#  name                  :string           default(""), not null
#  phone                 :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_companies_on_lower_email  (lower(NULLIF((email)::text, ''::text))) UNIQUE
#  index_companies_on_phone        (NULLIF((phone)::text, ''::text)) UNIQUE
#
require 'rails_helper'

RSpec.describe Company do
  let!(:account) { create(:account) }

  describe 'validations' do
    let(:valid_name) { 'Woofed' }
    let(:valid_email) { 'test@example.com' }
    let(:valid_phone) { '+123456789' }
    let(:other_email) { 'other@example.com' }
    let(:other_phone) { '+987654321' }

    context 'validates name' do
      context 'valid' do
        it 'when name is present' do
          new_company = build(:company, name: valid_name, email: valid_email, phone: valid_phone)

          expect(new_company).to be_valid
        end

        it 'when two companies have the same name' do
          create(:company, name: valid_name, email: valid_email, phone: valid_phone)
          new_company = build(:company, name: valid_name, email: other_email, phone: other_phone)

          expect(new_company.save).to be_truthy
        end
      end

      context 'invalid' do
        it 'when name is blank (empty string)' do
          new_company = build(:company, name: '', email: valid_email, phone: valid_phone)

          expect(new_company).to be_invalid
          expect(new_company.errors[:name]).to include("can't be blank")
        end

        it 'when name is nil' do
          new_company = build(:company, name: nil, email: valid_email, phone: valid_phone)

          expect(new_company).to be_invalid
          expect { new_company.save!(validate: false) }
            .to raise_error(ActiveRecord::NotNullViolation)
        end
      end
    end

    context 'validates email' do
      context 'valid' do
        it 'when email is unique (case-insensitive)' do
          create(:company, email: valid_email, phone: valid_phone)
          new_company = build(:company, email: other_email, phone: other_phone)

          expect(new_company.save).to be_truthy
        end

        it 'when email is blank (empty string)' do
          new_company = build(:company, email: '', phone: valid_phone)

          expect(new_company).to be_valid
        end

        it 'when multiple companies have blank email (empty string)' do
          create(:company, email: '', phone: valid_phone)
          create(:company, email: '', phone: other_phone)
          new_company = build(:company, email: '', phone: '+123456788')

          expect(new_company.save).to be_truthy
        end

        it 'when email has valid format' do
          new_company = build(:company, email: 'valid@example.com', phone: valid_phone)

          expect(new_company).to be_valid
        end
      end

      context 'invalid' do
        it 'when email is already taken (case-insensitive)' do
          create(:company, email: valid_email, phone: valid_phone)
          new_company = build(:company, email: valid_email.upcase, phone: other_phone)

          expect(new_company.save).to be_falsey
          expect(new_company.errors[:email]).to include('has already been taken')

          expect { new_company.save!(validate: false) }
            .to raise_error(ActiveRecord::RecordNotUnique)
        end

        it 'when email is nil' do
          new_company = build(:company, email: nil, phone: valid_phone)

          expect { new_company.save!(validate: false) }
            .to raise_error(ActiveRecord::NotNullViolation)
        end

        it 'when email has invalid format' do
          new_company = build(:company, email: 'invalid_email', phone: valid_phone)

          expect(new_company).to be_invalid
          expect(new_company.errors[:email]).to include(I18n.t('activerecord.errors.company.email.invalid'))
        end
      end
    end

    context 'validates phone' do
      context 'valid' do
        it 'when phone is unique' do
          create(:company, email: valid_email, phone: valid_phone)
          new_company = build(:company, email: other_email, phone: other_phone)

          expect(new_company.save).to be_truthy
        end

        it 'when phone is blank (empty string)' do
          new_company = build(:company, email: valid_email, phone: '')

          expect(new_company).to be_valid
        end

        it 'when multiple companies have blank phone (empty string)' do
          create(:company, email: valid_email, phone: '')
          create(:company, email: other_email, phone: '')
          new_company = build(:company, email: 'another@example.com', phone: '')

          expect(new_company.save).to be_truthy
        end

        it 'when phone has valid format' do
          new_company = build(:company, email: valid_email, phone: '+123456788')

          expect(new_company).to be_valid
        end

        it 'when phone does not start with + it is normalized to e164' do
          new_company = create(:company, email: valid_email, phone: '5511999999999')

          expect(new_company.phone).to eq('+5511999999999')
        end
      end

      context 'invalid' do
        it 'when phone is already taken' do
          create(:company, email: valid_email, phone: valid_phone)
          new_company = build(:company, email: other_email, phone: valid_phone)

          expect(new_company.save).to be_falsey
          expect(new_company.errors[:phone]).to include('has already been taken')

          expect { new_company.save!(validate: false) }
            .to raise_error(ActiveRecord::RecordNotUnique)
        end

        it 'when phone is more than 15 characters' do
          new_company = build(:company, email: valid_email, phone: '+552299881378888889')

          expect(new_company).to be_invalid
          expect(new_company.errors[:phone]).to include(I18n.t('activerecord.errors.company.phone.invalid'))
        end

        it 'when phone starts with +0' do
          new_company = build(:company, email: valid_email, phone: '+052299881378888889')

          expect(new_company).to be_invalid
          expect(new_company.errors[:phone]).to include(I18n.t('activerecord.errors.company.phone.invalid'))
        end

        it 'when phone is nil' do
          new_company = build(:company, email: valid_email, phone: nil)

          expect { new_company.save!(validate: false) }
            .to raise_error(ActiveRecord::NotNullViolation)
        end

        it 'when phone has invalid characters' do
          new_company = build(:company, email: valid_email, phone: 'invalid_phone')

          expect(new_company).to be_invalid
          expect(new_company.errors[:phone]).to include(I18n.t('activerecord.errors.company.phone.invalid'))
        end
      end
    end
  end

  describe 'associations' do
    let!(:company) { create(:company) }
    let!(:contact) { create(:contact) }

    context 'contacts' do
      it 'when a contact is linked it is reachable from both sides' do
        create(:company_contact, company:, contact:)

        expect(company.reload.contacts).to eq([contact])
        expect(contact.reload.companies).to eq([company])
      end

      it 'when a contact belongs to several companies' do
        other_company = create(:company)
        create(:company_contact, company:, contact:)
        create(:company_contact, company: other_company, contact:)

        expect(contact.reload.companies).to contain_exactly(company, other_company)
      end

      it 'when a company has no contacts' do
        expect(company.contacts).to be_empty
      end

      it 'when the company is destroyed it removes the link but keeps the contact' do
        create(:company_contact, company:, contact:)

        expect { company.destroy }.to change(CompanyContact, :count).by(-1)
                                                                   .and change(Contact, :count).by(0)
      end

      it 'when the contact is destroyed it removes the link but keeps the company' do
        create(:company_contact, company:, contact:)

        expect { contact.destroy }.to change(CompanyContact, :count).by(-1)
                                                                     .and change(Company, :count).by(0)
      end
    end

    context 'attachments' do
      it 'when files are attached they are grouped by file type' do
        company.attachments.create!(file: get_file('patrick.png'))
        company.attachments.create!(file: get_file('video_test.mp4'))
        company.attachments.create!(file: get_file('hello_world.txt'))

        expect(company.image_attachments.count).to eq(1)
        expect(company.video_attachments.count).to eq(1)
        expect(company.file_attachments.count).to eq(1)
      end

      it 'when the company is destroyed the attachments are removed' do
        company.attachments.create!(file: get_file('patrick.png'))

        expect { company.destroy }.to change(Attachment, :count).by(-1)
      end
    end
  end

  def get_file(name)
    Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/files/#{name}")
  end
end
