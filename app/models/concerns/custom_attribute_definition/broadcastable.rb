module CustomAttributeDefinition::Broadcastable
  extend ActiveSupport::Concern
  included do
    after_create_commit do
      broadcast_append_later_to [account, :custom_attribute_definition],
                                target: 'custom_attributes_definitions', partial: 'accounts/settings/custom_attributes_definitions/custom_attribute_definition', locals: { custom_attributes_definition: self }
    end
    after_update_commit do
      broadcast_replace_later_to [account, :custom_attribute_definition], target: self,
                                                                          partial: 'accounts/settings/custom_attributes_definitions/custom_attribute_definition', locals: { custom_attributes_definition: self }
    end
    after_destroy_commit do
      broadcast_remove_to [account, :custom_attribute_definition], target: self
    end
  end
end
