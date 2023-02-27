

//import { Controller } from "@hotwired/stimulus";
import { Controller } from "stimulus"
/*
 * Usage
 * =====
 *
 * add data-controller="navigate" to the turbo frame you want to navigate
 *
 * Action (add to radio input):
 * data-action="change->navigate#to"
 * data-url="/new?input=yes"
 *
 */
export default class extends Controller {
  connect(){
   console.log('start')
  }
  to(e) {
    console.log('eaeee')
    e.preventDefault();

    const { url } = e.target.dataset;

    this.element.src = url;
  }
}