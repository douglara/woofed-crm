class Deal::DragAndDrop
  def initialize(deal:, position:, new_stage_id: nil, element_reference_direction: nil)
    raise ArgumentError, 'deal is required' unless deal
    raise ArgumentError, 'position is required' unless position

    @deal = deal
    @new_stage_id = new_stage_id
    @position = position
    @element_reference_direction = element_reference_direction
  end

  def call
    return { error: 'invalid direction' } unless validate_direction

    { ok: Deal::CreateOrUpdate.new(deal, deal_params).call }
  end

  private

  attr_reader :deal, :new_stage_id, :position, :element_reference_direction

  def deal_params
    return { stage_id: new_stage_id, position: new_position } if move_between_stages?

    { position: new_position }
  end

  def new_position
    return position unless move_between_stages? || element_reference_direction.present?

    return position + 1 if element_reference_direction == 'bottom'

    return 1 if position == 1

    position - 1
  end

  def validate_direction
    [nil, 'bottom', 'top'].include?(element_reference_direction)
  end

  def move_between_stages?
    new_stage_id.present? && new_stage_id != deal.stage_id.to_s
  end
end
