import { Controller } from "@hotwired/stimulus";
import { Modal } from 'flowbite';
import { raiseOverlay } from "../utils/overlay_stack";

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
    raiseOverlay(this.element, this.backdrop)
    this.preventBackdropAfterMorphRefresh()
  }
	disconnect() {
		this.modal.hide()
	}
	// Dismisses the modal from a link inside it. Without this a modal that navigates another
	// frame (the advanced search opening the drawer) stays behind it and keeps holding
	// turbo-frame#modal, so nothing else can open a modal into that frame.
	// Deferred to the next tick on purpose: hiding removes the modal, and the clicked link is
	// inside it. Detaching the link while the click is still bubbling means Turbo no longer sees
	// its data-turbo-frame and downgrades the frame navigation to a full page load.
	hide() {
		setTimeout(() => this.modal.hide(), 0)
	}
	modalRemove() {
		this.element.remove()
	}
  preventBackdropAfterMorphRefresh(){
    this.backdrop.dataset.turboPermanent = true
  }
  get backdrop() {
    return document.getElementsByClassName("modal-backdrop")[0]
  }
}
