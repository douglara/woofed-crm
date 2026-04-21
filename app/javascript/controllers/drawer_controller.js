import { Controller } from "@hotwired/stimulus";
import { Drawer } from "flowbite";

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
      this.preventBackdropAfterMorphRefresh();
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
    const backdrop = document.getElementsByClassName("drawer-backdrop")[0];
    if (backdrop) {
      backdrop.dataset.turboPermanent = true;
      backdrop.addEventListener(
        "click",
        (event) => event.stopImmediatePropagation(),
        true,
      );
    }
  }
}
