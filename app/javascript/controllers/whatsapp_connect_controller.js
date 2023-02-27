import { Controller } from "stimulus"

export default class extends Controller {
	static targets = ['account_id', 'id']

	connect() {
		this.load(); 
  }

	async load () {
		const timer = ms => new Promise(res => setTimeout(res, ms))

		for (var i = 0; i < 45; i++) {
			let res = await this.is_connected()
			if (res['connceted'] == true) {
				await this.connected_redirect()
			}
			else {
				$("#qr_code").attr("src", res['qr_code']);
			}
			await timer(1000);
		}
	}
	
	async connected_redirect() {
		const account_id = this.account_idTarget.value
		window.location.replace(`/accounts/${account_id}/apps/wpp_connects`)
		await timer(100000);
	}

	async is_connected() {
		const id = this.idTarget.value
		const account_id = this.account_idTarget.value

		let res = await $.ajax({
			url : `/accounts/${account_id}/apps/wpp_connects/${id}/new_connection_status`,
			type : 'POST',
			dataType:'json'
		});
		return res
	}
}