# frozen_string_literal: true

# Which Woofed stage a Salesforce opportunity lands on.
#
# Salesforce stage names are free-form per record type -- "Prospecting" in one
# org, "Qualificação" in another, and nothing in common with the pipeline the
# customer built in Woofed. There is no way to infer the correspondence, so the
# user provides it on the mapping as `stage_map`, with `default_stage_id` for
# names the map does not cover.
#
# The namespace is plural on purpose: inside `Load::Deal::` the constant `Deal`
# would resolve to the namespace instead of the CRM model.
class Apps::Salesforce::Load::Deals::FindStage
  def self.call(object_mapping, stage_name)
    options = object_mapping.options

    Stage.find_by(id: options.dig('stage_map', stage_name.to_s) || options['default_stage_id'])
  end
end
