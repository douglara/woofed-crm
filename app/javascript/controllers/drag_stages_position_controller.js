import { Controller } from "stimulus"
import Sortable from "sortablejs"
import Rails from '@rails/ujs';


export default class extends Controller {
    connect() {
        this.Sortable = Sortable.create(this.element, {
            onEnd: this.end.bind(this)
        })
    }

    end(e) {
        let id = e.item.dataset.id
        let data = new FormData()
        data.append("pipeline[stages_attributes][][position]", e.newIndex + 1)
        data.append("pipeline[stages_attributes][][id]", id)
        Rails.ajax({
            url: this.data.get('url'),
            type: 'PATCH', 
            data: data,
        })
    }
}