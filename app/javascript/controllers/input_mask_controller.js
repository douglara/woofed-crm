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
                    mask: '+000000000000000',
                });
            }
            if (fieldName === 'contactcustomattributescpf') {
                field.placeholder = '000.000.000-00'
                new IMask(field, {
                    mask: '000.000.000-00',
                });
            }
            if (fieldName === 'contactcustomattributescnpj') {
                field.placeholder = '00.000.000/0000-00'
                new IMask(field, {
                    mask: '00.000.000/0000-00',
                });
            }
            if (fieldName === 'contactcustomattributescep') {
                field.placeholder = '00000-000'
                new IMask(field, {
                    mask: '00000-000',
                });
            }
        })
    }

}