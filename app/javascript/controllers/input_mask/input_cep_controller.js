import { Controller } from "stimulus"
import IMask from 'imask';

export default class extends Controller {
    connect(){
        new IMask(this.element, {
            mask: '00000-000',
        });
    }
}