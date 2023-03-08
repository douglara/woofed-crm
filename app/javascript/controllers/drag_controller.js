// Visit The Stimulus Handbook for more details 
// https://stimulusjs.org/handbook/introduction
// 
// This example controller works with specially annotated HTML like:
//
// <div data-controller="hello">
//   <h1 data-target="hello.output"></h1>
// </div>

import { Controller } from "stimulus"
import Sortable from "sortablejs"
import Rails from '@rails/ujs';
import { get, post, put, patch, destroy } from '@rails/request.js'


export default class extends Controller {

  connect() {
    this.initialise()
  }

  initialise() {
    this.sortable = Sortable.create(this.element, {
      group: "tasks",
      onEnd: this.end.bind(this)
    })
  }

  async end(event) {
    const id = event.item.firstElementChild.dataset.id
    const to_id = event.to.dataset.id
    let data = new FormData()
    //data.append("position", event.newIndex + 1)
    //let json = {"deal": {"stage_id": to_id}}


    const response = await put(this.data.get("url").replace(":deal_id", id),
    { body: JSON.stringify({"deal": {"stage_id": to_id}} )  }
    )
    console.log(response)

    // Rails.ajax({
    //   url: this.data.get("url").replace(":deal_id", id),
    //   type: "PUT",
		// 	headers: {
		// 		'Content-Type':'application/json',
		// 	},
		// 	dataType: 'json',
		// 	data: JSON.stringify({"deal": {"stage_id": to_id}} )
    // })
  }
}