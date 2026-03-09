Ransack.configure do |config|
  # Change default search parameter key name.
  # Default key name is :q
  config.search_key = :query

  # Raise errors if a query contains an unknown predicate or attribute.
  # Default is true (do not raise error on unknown conditions).
  config.ignore_unknown_conditions = false
end

ActsAsTaggableOn::Tag.class_eval do
  def self.ransackable_attributes(auth_object = nil)
    %w[
      name
      id
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end
end
