# frozen_string_literal: true

# Woofed requires E.164 (`+5511999999999`); Salesforce phone fields are free
# text: "(11) 99999-9999", "+55 11 99999 9999", "11 3333-4444 ext. 204".
#
# A number without a country code cannot be normalised without knowing which
# country it belongs to, and guessing would silently create contacts nobody can
# call. When there is no country code to apply, the value is reported as
# unconvertible so the caller can keep the original and import the record with a
# blank phone rather than dropping it.
class Apps::Salesforce::Transform::Phone
  E164 = /\A\+[1-9]\d{1,14}\z/

  def self.call(value, options = {})
    return { ok: nil } if value.blank?

    digits = extension_stripped(value)
    candidate = digits.start_with?('+') ? digits : with_country_code(digits, options['country_code'])

    return unconvertible(value) if candidate.blank? || !candidate.match?(E164)

    { ok: candidate }
  end

  # Everything from the first letter on is an extension or a note, never part of
  # the number.
  def self.extension_stripped(value)
    trimmed = value.to_s.strip.split(/[a-zA-Z]/).first.to_s
    sign = trimmed.start_with?('+') ? '+' : ''

    "#{sign}#{trimmed.gsub(/\D/, '')}"
  end

  def self.with_country_code(digits, country_code)
    return nil if country_code.blank? || digits.blank?

    "+#{country_code}#{digits.sub(/\A0+/, '')}"
  end

  def self.unconvertible(value)
    { error: I18n.t('apps.salesforce.transforms.invalid_phone', value: value), raw: value }
  end

  private_class_method :extension_stripped, :with_country_code, :unconvertible
end
