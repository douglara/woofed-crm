# frozen_string_literal: true

# Service for generating filter schema metadata from ActiveRecord models.
# Used by the DynamicFilter component to dynamically build filter UIs.
#
# Generates Motor Admin-like field list including:
# - Model's own attributes
# - Association attributes (e.g., "Contact - Full name" => contact_full_name)
# - Foreign key lookups with dynamic search endpoints
#
# Example usage:
#   SchemaBuilder.build(Deal, account, account_id: 1)
#
# Returns an array of field definitions with metadata for the filter UI.
class SchemaBuilder
  # Maps Rails column types to filter field types
  COLUMN_TYPE_MAP = {
    string: 'text',
    text: 'text',
    integer: 'number',
    bigint: 'number',
    float: 'number',
    decimal: 'number',
    boolean: 'boolean',
    date: 'date',
    datetime: 'date',
    jsonb: 'text',
    json: 'text'
  }.freeze

  # Fields to exclude from schema attributes
  EXCLUDED_FIELDS = %w[encrypted_password reset_password_token remember_token
                       confirmation_token unlock_token password_digest account_id].freeze

  # Associations to exclude from schema (internal/multi-tenant)
  EXCLUDED_ASSOCIATIONS = %w[account accounts].freeze

  class << self
    # Build schema for a given model class
    # @param model_class [Class] ActiveRecord model class
    # @param account [Account] Current account for loading options (optional)
    # @param options [Hash] Additional options (account_id for endpoint URLs)
    # @return [Array<Hash>] Array of field definitions
    def build(model_class, account = nil, options = {})
      return [] unless model_class.respond_to?(:ransackable_attributes)

      account_id = options[:account_id] || account&.id
      fields = []

      # 1. Build model's own attributes
      ransackable_attrs = model_class.ransackable_attributes(nil)
      columns = model_class.columns_hash

      ransackable_attrs.each do |attr|
        next if EXCLUDED_FIELDS.include?(attr)

        column = columns[attr]
        field = build_field(attr, column, model_class, account, account_id)
        fields << field if field
      end

      # 2. Build association nested attributes (Motor Admin style)
      if model_class.respond_to?(:ransackable_associations)
        ransackable_associations = model_class.ransackable_associations(nil)
        association_fields = build_nested_association_fields(model_class, ransackable_associations, account, account_id)
        fields.concat(association_fields)
      end

      fields
    end

    # Build schema for multiple resources
    # @param resources [Hash] Hash of resource_name => model_class
    # @param account [Account] Current account
    # @param options [Hash] Additional options
    # @return [Hash] Hash of resource_name => fields array
    def build_multiple(resources, account = nil, options = {})
      resources.transform_values do |model_class|
        build(model_class, account, options)
      end
    end

    private

    def build_field(attr, column, model_class, account, account_id, prefix: nil, assoc_label: nil)
      field_type = determine_field_type(attr, column, model_class)
      field_name = prefix ? "#{prefix}_#{attr}" : attr
      label = build_label(attr, model_class, assoc_label)

      field = {
        name: field_name,
        label:,
        type: field_type
      }

      # Add options for select fields (enums)
      if field_type == 'select' && model_class.respond_to?(:defined_enums) && model_class.defined_enums.key?(attr)
        field[:options] = model_class.defined_enums[attr].map do |key, _value|
          { value: key, label: key.humanize }
        end
      end

      # Add relation metadata for foreign key fields
      if attr.end_with?('_id')
        association_name = attr.sub(/_id$/, '')
        association = model_class.reflect_on_association(association_name.to_sym)

        add_relation_metadata(field, association, account, account_id) if association && !association.polymorphic?
      end

      field
    end

    def add_relation_metadata(field, association, _account, account_id)
      assoc_class = association.klass
      label_method = determine_label_method(assoc_class)

      field[:relation] = {
        model: assoc_class.name,
        modelName: assoc_class.name.underscore,
        labelKey: label_method.to_s,
        valueKey: 'id',
        searchKey: build_search_key(assoc_class, label_method)
      }
    end

    def build_search_key(assoc_class, label_method)
      search_fields = [label_method.to_s]
      search_fields << 'email' if assoc_class.column_names.include?('email')
      search_fields.join('_or_') + '_cont'
    end

    def determine_field_type(attr, column, model_class)
      # Check for enum fields
      return 'select' if model_class.respond_to?(:defined_enums) && model_class.defined_enums.key?(attr)

      # Check for foreign key relationships
      if attr.end_with?('_id')
        association = model_class.reflect_on_association(attr.sub(/_id$/, '').to_sym)
        return 'relation' if association && !association.polymorphic?
      end

      # Special cases
      return 'text' if %w[email phone].include?(attr)
      return 'date' if attr.end_with?('_at')

      # Default to column type mapping
      column_type = column&.type || :string
      COLUMN_TYPE_MAP[column_type] || 'text'
    end

    def build_label(attr, model_class, assoc_label)
      attr_label = if model_class.respond_to?(:human_attribute_name)
                     model_class.human_attribute_name(attr)
                   else
                     attr.humanize.titleize
                   end

      if assoc_label
        "#{assoc_label} - #{attr_label}"
      else
        attr_label
      end
    end

    # Maximum nesting depth for associations (e.g., Deal → Contact → Labels = depth 2)
    MAX_NESTING_DEPTH = 2

    def build_nested_association_fields(model_class, associations, account, account_id,
                                        prefix: nil, label_prefix: nil, depth: 1, visited: Set.new)
      return [] if depth > MAX_NESTING_DEPTH

      fields = []

      associations.each do |assoc_name|
        next if EXCLUDED_ASSOCIATIONS.include?(assoc_name.to_s)

        assoc = model_class.reflect_on_association(assoc_name.to_sym)
        next unless assoc
        next if assoc.polymorphic?

        begin
          assoc_class = assoc.klass
        rescue StandardError
          next
        end

        # Avoid circular references
        next if visited.include?(assoc_class.name)

        next unless assoc_class.respond_to?(:ransackable_attributes)

        current_visited = visited | Set[assoc_class.name]

        assoc_label = if label_prefix
                        "#{label_prefix} > #{assoc_name.to_s.humanize.titleize}"
                      else
                        assoc_name.to_s.humanize.titleize
                      end

        # Build Ransack prefix: e.g., "contact", "contact_labels"
        ransack_prefix = prefix ? "#{prefix}_#{assoc_name}" : assoc_name.to_s

        # Get association's ransackable attributes
        assoc_attrs = assoc_class.ransackable_attributes(nil)
        assoc_columns = assoc_class.columns_hash

        assoc_attrs.each do |attr|
          next if EXCLUDED_FIELDS.include?(attr)

          column = assoc_columns[attr]

          field = if attr == 'id'
                    build_association_id_field(assoc_name, assoc_class, account_id, ransack_prefix, assoc_label)
                  else
                    build_field(
                      attr,
                      column,
                      assoc_class,
                      account,
                      account_id,
                      prefix: ransack_prefix,
                      assoc_label:
                    )
                  end
          fields << field if field
        end

        # Recurse into sub-associations (nested relations)
        next unless assoc_class.respond_to?(:ransackable_associations)

        sub_associations = assoc_class.ransackable_associations(nil)
        nested_fields = build_nested_association_fields(
          assoc_class,
          sub_associations,
          account,
          account_id,
          prefix: ransack_prefix,
          label_prefix: assoc_label,
          depth: depth + 1,
          visited: current_visited
        )
        fields.concat(nested_fields)
      end

      fields
    end

    def build_association_id_field(assoc_name, assoc_class, account_id, ransack_prefix, assoc_label)
      field_name = "#{ransack_prefix}_id"
      label = "#{assoc_label} - ID"
      label_method = determine_label_method(assoc_class)

      field = {
        name: field_name,
        label:,
        type: 'relation',
        association: assoc_name.to_s
      }

      field[:relation] = {
        model: assoc_class.name,
        modelName: assoc_class.name.underscore,
        labelKey: label_method.to_s,
        valueKey: 'id',
        searchKey: build_search_key(assoc_class, label_method)
      }

      field
    end

    def determine_label_method(klass)
      # Use column_names to check for real DB-backed attributes (not inherited methods like to_s)
      label_candidates = %w[full_name name title display_name email]
      columns = klass.respond_to?(:column_names) ? klass.column_names : []

      label_candidates.find { |col| columns.include?(col) } || 'id'
    end
  end
end
