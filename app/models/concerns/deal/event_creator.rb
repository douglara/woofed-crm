module Deal::EventCreator
  extend ActiveSupport::Concern
  included do
    around_create :create_deal_and_event
    around_update :update_deal_and_create_event

    def create_deal_and_event
      transaction do
        yield
        create_event_log('deal_opened')
      end
    end

    def update_deal_and_create_event
      transaction do
        yield
        create_event_based_on_changes
      end
    end

    def create_event_based_on_changes
      return create_event_log('deal_won') if status_previously_changed?(to: 'won')
      return create_event_log('deal_lost') if status_previously_changed?(to: 'lost')
      return create_event_log('deal_reopened') if status_previously_changed?(to: 'open')

      create_event_log_stage_changes if stage_previously_changed?
    end
  end

  private

  def create_event_log_stage_changes
    old_stage_id, new_stage_id = previous_changes['stage_id']
    old_stage = Stage.find_by(id: old_stage_id) if old_stage_id
    new_stage = Stage.find_by(id: new_stage_id) if new_stage_id

    Event.create!(
      deal: self,
      kind: 'deal_stage_change',
      done: true,
      contact:,
      from_me: true,
      additional_attributes: {
        old_stage_id: old_stage.id,
        old_stage_name: old_stage.name,
        old_stage_pipeline_id: old_stage.pipeline.id,
        old_stage_pipeline_name: old_stage.pipeline.name,
        new_stage_id: new_stage.id,
        new_stage_name: new_stage.name,
        new_stage_pipeline_id: new_stage.pipeline.id,
        new_stage_pipeline_name: new_stage.pipeline.name,
        deal_name: name
      }
    )
  end

  def create_event_log(log_kind)
    Event.create!(
      deal: self,
      kind: log_kind,
      done: true,
      from_me: true,
      contact:,
      additional_attributes: {
        stage_id: stage.id,
        stage_name: stage.name,
        pipeline_id: pipeline.id,
        pipeline_name: pipeline.name,
        deal_name: name
      }
    )
  end
end
