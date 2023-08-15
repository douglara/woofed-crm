module ChatwootLabels
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :chatwoot_conversations_labels
    acts_as_taggable_on :chatwoot_contact_labels
  end

  def update_chatwoot_conversations_labels(labels = nil)
    update!(chatwoot_conversations_label_list: labels)
  end

  def add_chatwoot_conversations_labels(new_labels = nil)
    new_labels = Array(new_labels) # Make sure new_labels is an array
    combined_labels = chatwoot_conversations_labels + new_labels
    update!(chatwoot_conversations_label_list: combined_labels)
  end

  def update_chatwoot_contact_labels(labels = nil)
    update!(chatwoot_contact_label_list: labels)
  end

  def add_chatwoot_contact_labels(new_labels = nil)
    new_labels = Array(new_labels) # Make sure new_labels is an array
    combined_labels = chatwoot_contact_labels + new_labels
    update!(chatwoot_contact_label_list: combined_labels)
  end
end