# frozen_string_literal: true

# Starts the initial load: one run per enabled object mapping.
#
# Objects are queued in dependency order, so an Opportunity finds the Account it
# belongs to already imported instead of creating a placeholder for it.
#
# An object already being backfilled is skipped rather than queued twice: a
# second run would create a second bulk job on the org and download everything
# again.
class Apps::Salesforce::Backfill::Start
  DEPENDENCY_ORDER = %w[Account Contact Lead Opportunity Task Event].freeze

  def initialize(salesforce, kind: 'backfill')
    @salesforce = salesforce
    @kind = kind
  end

  def call
    return { error: I18n.t('apps.salesforce.missing_connection') } unless salesforce&.connected?

    runs = ordered_mappings.filter_map { |object_mapping| enqueue(object_mapping) }

    { ok: runs }
  end

  private

  attr_reader :salesforce, :kind

  def ordered_mappings
    salesforce.object_mappings.enabled.sort_by do |object_mapping|
      # Objects with no known dependency, custom ones included, go last.
      DEPENDENCY_ORDER.index(object_mapping.salesforce_object) || DEPENDENCY_ORDER.size
    end
  end

  def enqueue(object_mapping)
    return nil if already_running?(object_mapping)

    run = salesforce.sync_runs.create!(salesforce_object: object_mapping.salesforce_object, kind: kind)
    Apps::Salesforce::Backfill::ObjectJob.perform_later(run.id)

    run
  end

  def already_running?(object_mapping)
    salesforce.sync_runs.unfinished.exists?(salesforce_object: object_mapping.salesforce_object)
  end
end
