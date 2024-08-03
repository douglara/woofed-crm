class Accounts::Contacts::GetByParams
  def self.call(account, params)
    params.stringify_keys!
    return { error: 'Not found' } if params.blank?

    params.reject! { |_key, value| value.blank? }

    result = get_by_chatwoot_identifier(account, params['identifier'])
    params = params.slice('email', 'phone')
    query_params = params.map { |field, value| "#{field} ILIKE '%#{value}%'" }
    if params.key?('phone')
      query_params << "phone ILIKE '%#{sanitized_phone(params['phone'])}%'"
      query_params << "phone ILIKE '%#{phone_with_9_digit(params['phone'])}%'"
      query_params << "phone ILIKE '%#{phone_number_without_9_digit(params['phone'])}%'"
    end

    contact = account.contacts.where(query_params.join(' OR ')).first if query_params.present?
    result ||= { ok: contact }
    result
  end

  def self.phone_number_without_9_digit(phone)
    sanitized_phone = sanitized_phone(phone)

    if sanitized_phone.size == 13
      sanitized_phone
    else
      "#{sanitized_phone[0..4]}#{sanitized_phone[6..-1]}"

    end
  end

  def self.get_by_chatwoot_identifier(account, chatwoot_identifier)
    return nil unless chatwoot_identifier.present?

    contact = account.contacts.where("additional_attributes ->> 'chatwoot_identifier' = ?", chatwoot_identifier).first
    return nil unless contact.present?

    { ok: contact }
  end

  def self.phone_with_9_digit(phone)
    sanitized_phone = sanitized_phone(phone)
    if sanitized_phone.size >= 14
      sanitized_phone
    else
      "#{sanitized_phone[0..4]}9#{sanitized_phone[5..-1]}"

    end
  end

  def self.sanitized_phone(phone_number)
    raise TypeError, 'phone_number must be a String' unless phone_number.is_a?(String)

    cleaned_phone_number = phone_number.gsub(/\D/, '')
    cleaned_phone_number.prepend('+')
    cleaned_phone_number
  end
end
