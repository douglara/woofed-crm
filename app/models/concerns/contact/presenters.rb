module Contact::Presenters
  extend ActiveSupport::Concern

  def full_name_at_format
    full_name.blank? ? I18n.t('activerecord.models.contact.unknown', locale: I18n.locale) : full_name
  end
end
