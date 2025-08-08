import { Controller } from "stimulus"
import { Modal } from 'flowbite';

export default class extends Controller {
  connect() {
		this.modal = new Modal(this.element, {
			closable: false,
			backdrop: 'static',      
      backdropClasses:
        "bg-gray-900/50 dark:bg-gray-900/80 fixed inset-0 z-50 pointer-events-none",
		})
		this.modal.show()
  }
	disconnect() {
		this.modal.hide()
	}
	modalRemove() {
		this.element.remove()
	}
}
