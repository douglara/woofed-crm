# Calculates the target position for a deal being dropped near a reference card.
#
# The reference card's position is already reloaded (after remove_from_list),
# so the calculation is consistent regardless of same-stage or cross-stage moves.
#
# The Kanban displays deals ordered by position DESC (higher position = top of the list):
#
#   ┌─────────────────┐
#   │ Deal C (pos: 3) │  ← Top of the list (highest position)
#   ├─────────────────┤
#   │ Deal B (pos: 2) │
#   ├─────────────────┤
#   │ Deal A (pos: 1) │  ← Bottom of the list (lowest position)
#   └─────────────────┘
#
# Direction semantics (acts_as_list uses pure INSERT via insert_at):
#
# === Direction 'top' — reference is the card BELOW the drop (bottomElement)
#
#   ┌─────────────────┐         ┌─────────────────┐
#   │ Deal X (drop)   │ →       │ Deal X (pos: 3) │ ← reference + 1
#   ├─────────────────┤         ├─────────────────┤
#   │ Ref   (pos: 2)  │         │ Ref   (pos: 2)  │ ← stays in place
#   └─────────────────┘         └─────────────────┘
#
#   Result: new_position = reference.position + 1
#
# === Direction 'bottom' — reference is the card ABOVE the drop (topElement)
#
#   ┌─────────────────┐         ┌─────────────────┐
#   │ Ref   (pos: 2)  │ →       │ Ref   (pos: 3)  │ ← pushed up by insert_at
#   ├─────────────────┤         ├─────────────────┤
#   │ Deal X (drop)   │         │ Deal X (pos: 2) │ ← takes reference's old position
#   └─────────────────┘         └─────────────────┘
#
#   Result: new_position = reference.position
#
class Deal::DragAndDropPosition
  def initialize(reference_deal:, direction:)
    @reference_deal = reference_deal
    @direction      = direction&.downcase
    raise ArgumentError, 'invalid direction' unless valid_direction?
  end

  def call
    return @reference_deal.position if @direction == 'bottom'

    @reference_deal.position + 1
  end

  private

  def valid_direction?
    [nil, 'top', 'bottom'].include?(@direction)
  end
end
