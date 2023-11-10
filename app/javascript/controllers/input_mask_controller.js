import { Controller } from "stimulus"
import IMask from 'imask';

export default class extends Controller {
    connect(){
        const inputFields = this.element.querySelectorAll('input');

        inputFields.forEach(field => {
            const fieldName = field.name.replace(/[\[\]_\s]/g, '').toLowerCase()
            console.log(fieldName)
            if (fieldName === 'contactphone') {
                new IMask(field, {
                    mask: '+0000000000000000',
                });
            }
            if (fieldName === 'contactcustomattributescpf') {
                field.placeholder = '000.000.000-00'
                new IMask(field, {
                    mask: '000.000.000-00',
                });
            }
        })
    }

}