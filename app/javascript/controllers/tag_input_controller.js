import { Controller } from "stimulus"
import Tagify from '@yaireo/tagify';

export default class extends Controller {

  connect() {
    new Tagify(this.element, {
        originalInputValueFormat: valuesArr => valuesArr.map(item => item.value).join(',')
      }
    );
  }
}
