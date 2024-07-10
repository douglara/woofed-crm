module Localized
  extend ActiveSupport::Concern

  included do
    around_action :set_locale
  end

  def set_locale(&block)
    I18n.with_locale(requested_locale || I18n.default_locale, &block)
  end

  private

  def requested_locale
    if respond_to?(:user_signed_in?) && user_signed_in?
      requested_locale_name ||= available_locale_or_nil(current_user.language)
    end
    requested_locale_name
  end

  def available_locale_or_nil(locale_name)
    locale_name.to_sym if locale_name.present? && I18n.available_locales.map(&:to_s).include?(locale_name.to_s)
  end
end
