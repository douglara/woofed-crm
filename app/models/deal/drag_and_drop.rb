# Handles the drag-and-drop repositioning of a Deal on the Kanban board.
#
# acts_as_list behavior background
# ---------------------------------
# acts_as_list scopes positions per stage. When repositioning a deal, the gem
# behaves differently depending on whether the scope (stage) changes or not:
#
#   Same-stage move (ROTATE / shuffle):
#     Triggered by `after_update :update_positions` → `shuffle_positions_on_intermediate_items`.
#     Items between the old and new position are rotated. When moving a card
#     downward (old_pos < new_pos), intermediate items shift DOWN by 1, which
#     causes the card to land one slot too high — a subtle off-by-one bug.
#
#   Cross-stage move (INSERT):
#     Triggered by `before_update :check_scope` → `avoid_collision` →
#     `increment_positions_on_lower_items`. A slot is opened at the target
#     position by pushing all items at >= new_pos up by 1, then the deal is
#     placed there. This is correct and predictable.
#
# Why we use remove_from_list + insert_at
# ----------------------------------------
# Calling `remove_from_list` sets position to nil and closes the gap in the
# current stage. With position = nil, `in_list?` returns false, so a subsequent
# `insert_at` always uses the INSERT strategy (increment lower items), never
# ROTATE — making same-stage and cross-stage moves behave identically.
#
# Why acts_as_list_no_update is needed for stage changes
# -------------------------------------------------------
# If we simply call `update!(stage_id:)`, the gem's `check_scope` callback fires
# `avoid_collision`, which increments positions in the new stage immediately.
# Then `insert_at` would increment again, causing a double-shift. Using
# `acts_as_list_no_update` persists only the stage_id change with no position
# side-effects, keeping position = nil so `insert_at` behaves correctly.
#
# Why we reload the reference deal after remove_from_list
# -------------------------------------------------------
# When the deal is removed from the list, all items with a higher position in
# the same stage decrement by 1. If the reference deal was below the dragged
# deal (reference.position > deal.position), its position shifts down after
# removal. Reloading ensures we calculate the target position against the
# up-to-date value.
#
# Drop scenarios
# --------------
#   With reference element (element_reference_id present):
#     The JS identifies a neighbouring card and its direction ('top' or 'bottom').
#     The deal is fully repositioned via reposition_with_reference.
#
#   Without reference element, stage changed:
#     The user dropped onto an empty column or column header with no neighbour.
#     acts_as_list's check_scope / avoid_collision places the deal at the end
#     of the new stage automatically via a plain update!(stage_id:).
#     Using `else` instead of `elsif changing_stage?` would fire an unnecessary
#     UPDATE when stage did not change, triggering acts_as_list callbacks for no reason.
#
#   Without reference element, same stage:
#     Nothing changed — no action is taken.
class Deal::DragAndDrop
  def initialize(deal, stage_id:, element_reference_id: nil, element_reference_drop_direction: nil)
    @deal         = deal
    @new_stage_id = stage_id
    @reference_id = element_reference_id
    @direction    = element_reference_drop_direction
  end

  def call
    Deal.transaction do
      if @reference_id.present?
        reposition_with_reference
      elsif changing_stage?
        # remove_from_list sets position to nil so check_scope calls
        # add_to_list_bottom, placing the deal at max_position + 1 in the
        # new stage (visual top in the DESC-ordered Kanban board).
        @deal.remove_from_list
        @deal.update!(stage_id: @new_stage_id)
      end
    end

    @deal
  end

  private

  def reposition_with_reference
    # Sets position to nil and closes the gap in the current stage.
    # After this call, reference.position already reflects any shifted positions.
    @deal.remove_from_list

    if changing_stage?
      # Persist only the stage_id without triggering acts_as_list callbacks.
      # Keeps position = nil so the subsequent insert_at uses pure INSERT.
      Deal.acts_as_list_no_update { @deal.update!(stage_id: @new_stage_id) }
    end

    reference = Deal.find(@reference_id)
    position  = Deal::DragAndDropPosition.new(reference_deal: reference, direction: @direction).call
    @deal.insert_at(position)
  end

  def changing_stage?
    @deal.stage_id.to_s != @new_stage_id.to_s
  end
end
