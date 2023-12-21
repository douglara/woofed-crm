import { Controller } from "stimulus"
import { Modal } from 'flowbite';

export default class extends Controller {
  connect() {
		this.modal = new Modal(this.element, {
			closable: false,
			backdrop: 'static'
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
