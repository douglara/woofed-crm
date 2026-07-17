import { Controller } from "@hotwired/stimulus";
import { Drawer } from "flowbite";
import { raiseOverlay } from "../utils/overlay_stack";

export default class extends Controller {
  connect() {
    this.removeStaleBackdrops();
    this.drawer = new Drawer(this.element, {
      placement: "right",
      backdrop: true,
      bodyScrolling: false,
      backdropClasses:
        "bg-gray-900/50 dark:bg-gray-900/80 fixed inset-0 z-50 drawer-backdrop",
      onHide: () => {
        setTimeout(() => {
          this.element.remove();
        }, 300);
      },
    });
    setTimeout(() => {
      this.drawer.show();
      raiseOverlay(this.element, this.backdrop);
      this.preventBackdropAfterMorphRefresh();
      this.preventBackdropClickFromClosingDrawer();
    }, 100);
  }
  disconnect() {
    this.drawer.hide();
    this.removeStaleBackdrops();
  }
  removeStaleBackdrops() {
    document.querySelectorAll(".drawer-backdrop").forEach((el) => el.remove());
  }
  drawerHide(event) {
    event.preventDefault();
    this.drawer.hide();
  }
  preventMorphForDrawer(event) {
    event.preventDefault();
  }
  preventBackdropAfterMorphRefresh() {
    if (this.backdrop) {
      this.backdrop.dataset.turboPermanent = true;
    }
  }
  preventBackdropClickFromClosingDrawer() {
    this.backdrop.addEventListener(
      "click",
      (event) => event.stopImmediatePropagation(),
      true,
    );
  }
  get backdrop() {
    return document.getElementsByClassName("drawer-backdrop")[0];
  }
}
