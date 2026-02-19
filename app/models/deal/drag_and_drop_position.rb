class Deal::DragAndDropPosition
  def initialize(deal_reference_position:, deal_reference_direction: nil)
    raise ArgumentError, 'deal_reference_position is required' unless deal_reference_position

    @deal_reference_position = deal_reference_position&.to_i
    @deal_reference_direction = deal_reference_direction&.downcase

    raise ArgumentError, 'invalid direction' unless validate_direction
  end

  def call
    new_position
  end

  private

  attr_reader :deal_reference_position, :deal_reference_direction

  def new_position
    return deal_reference_position unless deal_reference_direction.present?

    return deal_reference_position + 1 if deal_reference_direction == 'bottom'

    return 1 if deal_reference_position == 1

    deal_reference_position - 1
  end

  def validate_direction
    [nil, 'bottom', 'top'].include?(deal_reference_direction)
  end
end
