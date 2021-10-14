import { Controller } from "stimulus"

export default class extends Controller {
	static targets = ['token', 'secretkey', 'endpoint_url', 'session']

	connect() {
		this.load(); 
  }

	async load () {
		const timer = ms => new Promise(res => setTimeout(res, ms))

		for (var i = 0; i < 45; i++) {
			let res = await this.is_connected()
			if (res['connceted'] == true) {
				$("#pair-form").submit();
			}
			else {
				$("#qr_code").attr("src", res['qr_code']);
			}
			await timer(1000);
		}
	}
	

	async is_connected() {
		const token = this.tokenTarget.value
		const secretkey = this.secretkeyTarget.value
		const endpoint_url = this.endpoint_urlTarget.value
		const session = this.sessionTarget.value

		let res = await $.ajax({
			url : '/settings/whatsapp/new_connection_status',
			type : 'POST',
			data: {
				"flow_items_activities_kinds_wp_connect": {
					"token": `${token}`, 
					"secretkey": `${secretkey}`, 
					"endpoint_url": `${endpoint_url}`,
					"session": `${session}`	
				} 
			},
			dataType:'json'
		});
		return res
	}
}