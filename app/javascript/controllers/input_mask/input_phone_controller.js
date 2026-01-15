import { Controller } from "@hotwired/stimulus"
import IMask from 'imask';

export default class extends Controller {
    connect(){
        new IMask(this.element, {
            mask: '+000000000000000',
        });
    }

}