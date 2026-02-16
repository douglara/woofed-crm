class Deal::DragAndDrop
  def initialize(deal:, position:, new_stage: nil, closest_deal_direction: nil)
    raise ArgumentError, 'deal is required' unless deal
    raise ArgumentError, 'position is required' unless position

    @deal = deal
    @new_stage = new_stage
    @position = position
    @closest_deal_direction = closest_deal_direction
  end

  def call
    validate_direction

    Deal::CreateOrUpdate.new(deal, deal_params).call
  end

  private

  attr_reader :deal, :new_stage, :position, :closest_deal_direction

  def deal_params
    return { stage_id: new_stage.id, position: new_position } if move_between_stages?

    { position: new_position }
  end

  def new_position
    return position unless move_between_stages? || closest_deal_direction.nil?

    return position + 1 if closest_deal_direction == 'bottom'

    return 1 if position == 1

    position - 1
  end

  def validate_direction
    raise ArgumentError, 'invalid direction' unless [nil, 'bottom', 'top'].include?(closest_deal_direction)
  end

  def move_between_stages?
    new_stage.present? && new_stage != deal.stage
  end
end
