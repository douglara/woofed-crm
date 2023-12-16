import { Controller } from "stimulus"
import IMask from 'imask';

export default class extends Controller {
    connect(){
        new IMask(this.element, {
            mask: '00.000.000/0000-00',
        });
    }
         
}