module Deal::EventCreator
  extend ActiveSupport::Concern
  included do
    around_create :create_deal_and_event
    around_update :update_deal_and_create_event

    def create_deal_and_event
      transaction do
        yield
        Event.create!(
          deal: self,
          kind: 'deal_opened',
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
    rescue ActiveRecord::RecordInvalid => e
      handle_event_creation_error(e)
    end

    def update_deal_and_create_event
      transaction do
        yield
        create_event_based_on_changes
      end
    rescue ActiveRecord::RecordInvalid => e
      handle_event_creation_error(e)
    end

    def create_event_based_on_changes
      if previous_changes.except('updated_at').keys == ['status']
        if status == 'won'
          Event.create!(
            deal: self,
            kind: 'deal_won',
            done: true,
            contact:,
            from_me: true,
            additional_attributes: {
              stage_id: stage.id,
              stage_name: stage.name,
              pipeline_id: pipeline.id,
              pipeline_name: pipeline.name,
              deal_name: name
            }
          )
        elsif status == 'lost'
          Event.create!(
            deal: self,
            kind: 'deal_lost',
            done: true,
            contact:,
            from_me: true,
            additional_attributes: {
              stage_id: stage.id,
              stage_name: stage.name,
              pipeline_id: pipeline.id,
              pipeline_name: pipeline.name,
              deal_name: name
            }
          )
        else
          Event.create!(
            deal: self,
            kind: 'deal_reopened',
            done: true,
            contact:,
            from_me: true,
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
      return unless previous_changes.key?('stage_id')

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

    def handle_event_creation_error(e)
      if e.record.is_a?(DealProduct)
        errors.add(:base, "#{DealProduct.model_name.human} #{e.message}")
      elsif e.record.is_a?(Event)
        errors.add(:base, "#{Event.model_name.human} #{e.message}")
      else
        errors.add(:base, "#{DealProduct.model_name.human} #{Event.model_name.human} #{e.message}")
      end
      raise ActiveRecord::Rollback
    end
  end
end
