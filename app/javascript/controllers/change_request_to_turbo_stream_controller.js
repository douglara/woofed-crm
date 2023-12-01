import { Controller } from "stimulus"

export default class extends Controller {

  connect() {
    console.log("conectado")
  }


  changeHeader(event) {
    event.preventDefault()
    const href = event.currentTarget.href
    fetch(href,{
        headers:{
          Accept: 'text/vnd.turbo-stream.html'
        }
      }
    )
    .then(response => response.text())
    .then(html => Turbo.renderStreamMessage(html))
  }
}