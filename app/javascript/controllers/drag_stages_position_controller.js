import { Controller } from "stimulus";
import Sortable from "sortablejs";
import Rails from '@rails/ujs';

export default class extends Controller {
    connect() {
    this.moveFormFieldInputsToNestedFields();
    this.Sortable = Sortable.create(this.element, {
      onEnd: this.end.bind(this)
    });
  }

  moveFormFieldInputsToNestedFields() {
    const formFieldInputsSelector = 'input[type="hidden"][name^="pipeline[stages_attributes]"][id^="pipeline_stages_attributes_"]';

    document.querySelectorAll(formFieldInputsSelector).forEach(input => {
      const stageId = input.value;
      const targetDiv = document.querySelector(`div[data-id="${stageId}"]`);
      if (targetDiv) {
        targetDiv.appendChild(input);
      }
    });
  }

  end(e) {
    let id = e.item.dataset.id;
    let data = new FormData();
    data.append("pipeline[stages_attributes][][position]", e.newIndex + 1);
    data.append("pipeline[stages_attributes][][id]", id);
    Rails.ajax({
      url: this.data.get('url'),
      type: 'PATCH',
      data: data,
    });
  }
}
