# frozen_string_literal: true

module DealFilterHelper
  def deal_filter_models_json
    models = [
      { key: 'deal', label: Deal.model_name.human, prefix: '' },
      { key: 'contact', label: Contact.model_name.human, prefix: 'contact_' },
      { key: 'creator', label: t('views.accounts.pipelines.filter_builder.creator', default: 'Creator'), prefix: 'creator_' },
      { key: 'users', label: t('views.accounts.pipelines.filter_builder.assignees', default: 'Assignees'), prefix: 'users_' }
    ]
    models.to_json
  end

  def deal_filter_fields_by_model_json
    {
      deal: deal_fields,
      contact: contact_fields,
      creator: creator_fields,
      users: users_fields
    }.to_json
  end

  def deal_filter_operators_json
    {
      text: [
        { value: '_cont', label: t('views.accounts.pipelines.filter_builder.operators.contains', default: 'Contains') },
        { value: '_not_cont', label: t('views.accounts.pipelines.filter_builder.operators.not_contains', default: 'Does not contain') },
        { value: '_eq', label: t('views.accounts.pipelines.filter_builder.operators.equals', default: 'Equals') },
        { value: '_not_eq', label: t('views.accounts.pipelines.filter_builder.operators.not_equals', default: 'Does not equal') },
        { value: '_present', label: t('views.accounts.pipelines.filter_builder.operators.present', default: 'Has any value') },
        { value: '_blank', label: t('views.accounts.pipelines.filter_builder.operators.blank', default: 'Is empty') }
      ],
      select: [
        { value: '_eq', label: t('views.accounts.pipelines.filter_builder.operators.equals', default: 'Equals') },
        { value: '_not_eq', label: t('views.accounts.pipelines.filter_builder.operators.not_equals', default: 'Does not equal') }
      ],
      multi_select: [
        { value: '_in', label: t('views.accounts.pipelines.filter_builder.operators.includes', default: 'Includes any of') },
        { value: '_not_in', label: t('views.accounts.pipelines.filter_builder.operators.excludes', default: 'Excludes all of') }
      ],
      number: [
        { value: '_eq', label: t('views.accounts.pipelines.filter_builder.operators.equals', default: 'Equals') },
        { value: '_gteq', label: t('views.accounts.pipelines.filter_builder.operators.greater_or_equal', default: 'Greater than or equal') },
        { value: '_lteq', label: t('views.accounts.pipelines.filter_builder.operators.less_or_equal', default: 'Less than or equal') }
      ],
      date: [
        { value: '_eq', label: t('views.accounts.pipelines.filter_builder.operators.on', default: 'On') },
        { value: '_gteq', label: t('views.accounts.pipelines.filter_builder.operators.after', default: 'On or after') },
        { value: '_lteq', label: t('views.accounts.pipelines.filter_builder.operators.before', default: 'On or before') }
      ],
      datetime: [
        { value: '_eq', label: t('views.accounts.pipelines.filter_builder.operators.on', default: 'On') },
        { value: '_gteq', label: t('views.accounts.pipelines.filter_builder.operators.after', default: 'On or after') },
        { value: '_lteq', label: t('views.accounts.pipelines.filter_builder.operators.before', default: 'On or before') }
      ]
    }.to_json
  end

  def deal_filter_users_json
    User.all.map { |u| { id: u.id, name: u.full_name || u.email } }.to_json
  end

  private

  def deal_fields
    fields = []

    # Standard Deal attributes from ransackable_attributes
    Deal.ransackable_attributes.each do |attr|
      next if %w[contact_id stage_id pipeline_id created_by_id position].include?(attr)

      fields << build_field_config(Deal, attr, '')
    end

    # Deal status with options
    fields.find { |f| f[:key] == 'status' }&.merge!(
      type: 'select',
      options: Deal.statuses.map { |k, _v| { value: k, label: t("activerecord.attributes.deal.statuses.#{k}", default: k.humanize) } }
    )

    # Custom attributes for Deal
    CustomAttributeDefinition.where(attribute_model: 'deal_attribute').each do |custom_attr|
      fields << {
        key: "custom_attributes_#{custom_attr.attribute_key}",
        label: custom_attr.attribute_display_name,
        type: custom_attribute_type(custom_attr)
      }
    end

    fields
  end

  def contact_fields
    fields = []

    # Standard Contact attributes from ransackable_attributes
    Contact.ransackable_attributes.each do |attr|
      next if %w[id additional_attributes custom_attributes app_id app_type].include?(attr)

      fields << build_field_config(Contact, attr, 'contact_')
    end

    # Custom attributes for Contact
    CustomAttributeDefinition.where(attribute_model: 'contact_attribute').each do |custom_attr|
      fields << {
        key: "contact_custom_attributes_#{custom_attr.attribute_key}",
        label: custom_attr.attribute_display_name,
        type: custom_attribute_type(custom_attr)
      }
    end

    fields
  end

  def creator_fields
    fields = []

    # User attributes for creator
    %w[full_name email phone].each do |attr|
      fields << build_field_config(User, attr, 'creator_')
    end

    fields
  end

  def users_fields
    [
      {
        key: 'users_id',
        label: t('views.accounts.pipelines.filter_builder.assigned_users', default: 'Assigned users'),
        type: 'multi_select'
      }
    ]
  end

  def build_field_config(model, attr, prefix)
    column = model.columns_hash[attr]
    {
      key: "#{prefix}#{attr}",
      label: t("activerecord.attributes.#{model.model_name.i18n_key}.#{attr}", default: attr.humanize),
      type: column_to_filter_type(column)
    }
  end

  def column_to_filter_type(column)
    return 'text' unless column

    case column.type
    when :string, :text
      'text'
    when :integer, :bigint, :decimal, :float
      'number'
    when :date
      'date'
    when :datetime
      'datetime'
    when :boolean
      'boolean'
    else
      'text'
    end
  end

  def custom_attribute_type(_custom_attr)
    # TODO: Map custom attribute types when available
    'text'
  end
end
