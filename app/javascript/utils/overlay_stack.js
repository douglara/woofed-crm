// A drawer and a modal can be opened over one another in either order (a modal opened from a
// drawer section, or a link inside a modal opening a drawer), so the overlay opened last has to
// win. A fixed z-index class cannot express that, so each overlay asks for a z-index above
// whatever is currently open. Once every overlay closes, the next one starts from BASE_Z_INDEX
// again, which keeps the values from creeping upwards over time.
//
// Overlays therefore climb past any z-index written in a class: anything that must stay on top of
// them (the flash message toast) sits on the z-[1000] tier instead of just above BASE_Z_INDEX.
const BASE_Z_INDEX = 60;
const STEP = 10;
const OVERLAY_SELECTOR = "#drawer-right, #modal";

export function raiseOverlay(element, backdrop) {
  let highest = BASE_Z_INDEX;

  document.querySelectorAll(OVERLAY_SELECTOR).forEach((overlay) => {
    if (overlay === element) return;
    highest = Math.max(
      highest,
      parseInt(overlay.style.zIndex, 10) || BASE_Z_INDEX,
    );
  });

  const zIndex = highest + STEP;
  element.style.zIndex = zIndex;
  // Keep the backdrop directly under its own overlay so it covers whatever is below it.
  if (backdrop) backdrop.style.zIndex = zIndex - 1;
}
