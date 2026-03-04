/**
 * Builds parameters for drag and drop operations in the Kanban board.
 *
 * This class is responsible ONLY for identifying:
 *   1. The reference card (the card near where the item was dropped)
 *   2. The drop direction ('top' or 'bottom') relative to the reference card
 *
 * The actual position calculation is handled by the backend (Deal::DragAndDropPosition).
 *
 * Two scenarios are handled:
 *   1. With reference card: Returns { element_reference_id, element_reference_drop_direction }
 *   2. Without reference card (empty stage): Returns {}
 *      The backend places the deal at the last position (top visual in DESC order)
 *
 * DOM structure after drop:
 *   - topElement (previousElementSibling): Card visually ABOVE the dropped item
 *   - bottomElement (nextElementSibling): Card visually BELOW the dropped item
 */
export default class DropParamsBuilder {
  constructor(event) {
    this.event = event;
    this.topElement = event.item.previousElementSibling || null;
    this.bottomElement = event.item.nextElementSibling || null;
  }

  /**
   * Determines the reference card and direction based on drop position.
   *
   * Case 1: bottomElement exists (dropping at top/middle)
   *   ┌─────────────────┐
   *   │ Deal X (drop)   │ ← Want to be ABOVE bottomElement
   *   ├─────────────────┤
   *   │ Deal B (pos: 2) │ ← bottomElement
   *   └─────────────────┘
   *   Sends: { reference: Deal_B, direction: 'top' } → position = 2
   *
   * Case 2: Only topElement exists (dropping at bottom)
   *   ┌─────────────────┐
   *   │ Deal B (pos: 2) │ ← topElement
   *   ├─────────────────┤
   *   │ Deal X (drop)   │ ← Want to be BELOW topElement
   *   └─────────────────┘
   *   Sends: { reference: Deal_B, direction: 'bottom' } → position = 3
   *
   * Case 3: Empty column (no siblings)
   *   Sends: {} → backend places at last position
   */
  buildDropParams() {
    if (this.bottomElement) {
      return {
        element_reference_id: this.bottomElement.dataset.id,
        element_reference_drop_direction: "top",
      };
    }

    if (this.topElement) {
      return {
        element_reference_id: this.topElement.dataset.id,
        element_reference_drop_direction: "bottom",
      };
    }

    return {};
  }
}
