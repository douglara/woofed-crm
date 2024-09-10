import { Controller } from "stimulus"
const SIP = require('sip.js');

export default class extends Controller {
	static targets = [ "connect", "localAudio", "remoteAudio", "disconnect", "acceptCall", "hangup", "register", "makeCall", "numberToCall" ]
  static values = {
    websocketServer: String,
    server: String,
    userName: String,
    password: String,
    name: String
  }

  connect() {
		this.connectTarget.disabled = false;
  }

  sipConnect() {
    let server = `wss://${this.websocketServerValue}`;
    let options = {
        aor: `sip:${this.userNameValue}@${this.serverValue}`,
        userAgentOptions: {
            authorizationUsername: this.userNameValue,
            authorizationPassword: this.passwordValue
        },
        media: {
            remote: {
                audio: document.getElementById("remoteAudio")
            }
        }
    };

    this.simpleUser = new SIP.Web.SimpleUser(server, options);
    this.simpleUser.connect()
    .then(() => {
      console.log('Conectou')
      this.connectTarget.disabled = true;
      this.disconnectTarget.disabled = false;
      // hangupButton.disabled = true;
      this.registerTarget.disabled = false;
    })
    .catch((error) => {
      // connectButton.disabled = false;
      console.error(`[${simpleUser.id}] failed to connect`);
      console.error(error);
      alert("Failed to connect.\n" + error);
    });

    this.simpleUser.delegate = {
      onCallReceived: (session) => {
        console.log('Recebendo uma ligação......')
        this.acceptCallTarget.disabled = false;
        
      }
    }
   

  }

  acceptCall() {
    this.simpleUser.answer();
    this.acceptCallTarget.disabled = true;
  }

  register(){
    this.simpleUser.register({
      // An example of how to get access to a SIP response message for custom handling
      requestDelegate: {
        onReject: (response) => {
          console.warn(`[${user.id}] REGISTER rejected`);
          let message = `Registration of "${user.id}" rejected.\n`;
          message += `Reason: ${response.message.reasonPhrase}\n`;
          alert(message);
        }
      }
    })
    .then(() => {
      this.registerTarget.disabled = true;
    })
    .catch((error) => {
      console.error(`[${user.id}] failed to register`);
      console.error(error);
      alert(`[${user.id}] Failed to register.\n` + error);
    });




    this.simpleUser.on('ringing', function() {
      console.log('Recebendo uma ligação......')
      // simple.answer();
    });

  }

  disconnect() {
    this.connectTarget.disabled = true;
    this.disconnectTarget.disabled = true;
    // this.callTarget.disabled = true;
    this.hangupTarget.disabled = true;
    this.simpleUser
      .disconnect()
      .then(() => {
        this.connectTarget.disabled = false;
        this.disconnectTarget.disabled = true;
        // this.callTarget.disabled = true;
        this.hangupTarget.disabled = true;
      })
      .catch((error) => {
        console.error(`[${simpleUser.id}] failed to disconnect`);
        console.error(error);
        alert("Failed to disconnect.\n" + error);
      });
  }

	makeCall() {
    console.log(`Call to ${this.numberToCallTarget.value}`);
    const disconnect = `sip:${this.numberToCallTarget.value}@${this.serverValue}`;
    this.simpleUser
      .call(destination, {
        inviteWithoutSdp: false
      })
      .catch((error) => {
        console.error(`[${simpleUser.id}] failed to place call`);
        console.error(error);
        alert("Failed to place call.\n" + error);
      });
	}
}
