import { Controller } from "stimulus"

export default class extends Controller {
  toggle() {
    this.element.classList.toggle('sidebar-mini');
    this.element.classList.toggle('w-60');
    this.element.classList.toggle('w-[72px]');
  }
}