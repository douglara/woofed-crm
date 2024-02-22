module CustomAttributeDefinition::Broadcastable
  extend ActiveSupport::Concern
  included do
    after_create_commit {
      broadcast_append_later_to "custom_attributes_definitions_#{self.account.id}", target: 'custom_attributes_definitions', partial: 'accounts/settings/custom_attributes_definitions/custom_attribute_definition', locals: {custom_attributes_definition: self}
    }
    after_update_commit {
      broadcast_replace_later_to "custom_attributes_definitions_#{self.account.id}", target: self, partial: 'accounts/settings/custom_attributes_definitions/custom_attribute_definition', locals: {custom_attributes_definition: self}
    }
    after_destroy_commit {
      broadcast_remove_to "custom_attributes_definitions_#{self.account.id}", target: self
    }
  end
end
