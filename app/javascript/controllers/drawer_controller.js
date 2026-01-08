import { Controller } from "stimulus";
import { Drawer } from "flowbite";

export default class extends Controller {
  connect() {
    this.drawer = new Drawer(this.element, {
      placement: "right",
      backdrop: true,
      bodyScrolling: false,
      backdropClasses:
        "bg-gray-900/50 dark:bg-gray-900/80 fixed inset-0 z-50 pointer-events-none",
      onHide: () => {
        setTimeout(() => {
          this.element.remove();
        }, 300);
      },
    });
    setTimeout(() => {
      this.drawer.show();
    }, 100);
  }
  disconnect() {
    this.drawer.hide();
  }
  drawerHide(event) {
    event.preventDefault();
    this.drawer.hide();
  }
}
