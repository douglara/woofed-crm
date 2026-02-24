import { Controller } from "@hotwired/stimulus";
import { Modal } from 'flowbite';

export default class extends Controller {
  static values = {
    placement: String,
    closeable: Boolean,
    backdrop: String,
  }
  connect() {
		this.modal = new Modal(this.element, {
      placement: this.placementValue,
			closable: this.closeableValue,
			backdrop: this.backdropValue,
      backdropClasses:
        "bg-gray-900/50 dark:bg-gray-900/80 fixed inset-0 z-50 pointer-events-none modal-backdrop",
      onHide: () => {
        this.modalRemove()
      },
		})
		this.modal.show()
    this.preventBackdropAfterMorphRefresh()
  }
	disconnect() {
		this.modal.hide()
	}
	modalRemove() {
		this.element.remove()
	}
  preventBackdropAfterMorphRefresh(){
    const backdrop = document.getElementsByClassName("modal-backdrop")[0]
    backdrop.dataset.turboPermanent = true
  }
}
