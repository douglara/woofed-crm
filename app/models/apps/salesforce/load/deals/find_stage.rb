# frozen_string_literal: true

# Which Woofed stage a Salesforce record lands on.
#
# The match is by name, ignoring case and outer space: a customer whose Woofed
# stage is called "Qualificação" and whose Salesforce value is "Qualificação" has
# already described the correspondence by naming them alike, and asking them to
# restate it in a form would be asking twice.
#
# `options['stage_map']` overrides it, for the names that do differ, and is tried
# first so an explicit correspondence always beats a coincidence of naming. It
# has no UI yet, so today the name is the whole mechanism.
#
# Stage names are unique in neither direction, so a name living in two pipelines
# resolves by pipeline name and then position. Which pipeline the deal lands on
# follows from the stage it was put on, and landing on the same one every run
# matters more than which one it is -- an unordered read would move the record
# between pipelines from sync to sync.
#
# The namespace is plural on purpose: inside `Load::Deal::` the constant `Deal`
# would resolve to the namespace instead of the CRM model.
class Apps::Salesforce::Load::Deals::FindStage
  def self.call(object_mapping, stage_name)
    options = object_mapping.options

    mapped(options, stage_name) || named(stage_name) || default(options)
  end

  def self.mapped(options, stage_name)
    Stage.find_by(id: options.dig('stage_map', stage_name.to_s))
  end

  def self.named(stage_name)
    name = stage_name.to_s.strip
    return nil if name.blank?

    Stage.ordered_by_pipeline_and_position.where('lower(stages.name) = ?', name.downcase).first
  end

  def self.default(options)
    Stage.find_by(id: options['default_stage_id'])
  end

  private_class_method :mapped, :named, :default
end
