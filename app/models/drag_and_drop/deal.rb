class DragAndDrop::Deal < DragAndDrop::DropPosition
  def initialize(deal:, deal_reference_position:, deal_reference_direction: nil, new_stage_id: nil)
    raise ArgumentError, 'deal is required' unless deal
    raise ArgumentError, 'deal_reference_position is required' unless deal_reference_position

    @deal = deal
    @new_stage_id = new_stage_id&.to_i
    @deal_reference_position = deal_reference_position
    @deal_reference_direction = deal_reference_direction&.downcase

    super(element_reference_position: deal_reference_position, element_reference_direction: deal_reference_direction)
  end

  def call
    @position = super
    { ok: Deal::CreateOrUpdate.new(deal, deal_params).call }
  end

  private

  attr_reader :deal, :new_stage_id, :deal_reference_position, :deal_reference_direction, :position

  def deal_params
    return { stage_id: new_stage_id, position: } if move_between_stages?

    { position: }
  end

  def move_between_stages?
    new_stage_id.present? && new_stage_id != deal.stage_id
  end
end
