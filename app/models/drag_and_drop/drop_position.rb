class DragAndDrop::DropPosition
  def initialize(element_reference_position:, element_reference_direction: nil)
    raise ArgumentError, 'element_reference_position is required' unless element_reference_position

    @element_reference_position = element_reference_position
    @element_reference_direction = element_reference_direction&.downcase

    raise ArgumentError, 'invalid direction' unless validate_direction
  end

  def call
    new_position
  end

  private

  attr_reader :element_reference_position, :element_reference_direction

  def new_position
    return element_reference_position unless element_reference_direction.present?

    return element_reference_position + 1 if element_reference_direction == 'bottom'

    return 1 if element_reference_position == 1

    element_reference_position - 1
  end

  def validate_direction
    [nil, 'bottom', 'top'].include?(element_reference_direction)
  end
end
