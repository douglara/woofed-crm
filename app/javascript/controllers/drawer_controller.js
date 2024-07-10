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
    });
    this.drawer.show();
  }
  disconnect() {
    this.drawer.hide();
  }
  modalRemove() {
    this.drawer.remove();
  }
}
