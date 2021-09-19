import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
		this.load(); 
  }


	async load () {
		const timer = ms => new Promise(res => setTimeout(res, ms))

		for (var i = 0; i < 20; i++) {
			let res = await this.is_connected()
			if (res == true) {
				window.location.href = "/settings/whatsapp/edit";
			}
			await timer(3000);
		}
	}
	

	async is_connected() {
		let res = await $.ajax({
			url : '/settings/whatsapp/new_connection_status',
			type : 'GET',
			dataType:'json'
		});
		return res['connceted']
	}
}