import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["colorPicker", "colorInput"]

  connect() {
    this.setupColorSync()
  }

  setupColorSync() {
    // Sincronizar color picker com text input
    this.colorPickerTargets.forEach(picker => {
      // Remove listeners anteriores para evitar duplica??o
      picker.removeEventListener("input", this.handleColorPickerChange)
      picker.addEventListener("input", this.handleColorPickerChange.bind(this))
    })

    // Sincronizar text input com color picker (quando o usu?rio digita)
    this.colorInputTargets.forEach(input => {
      // Remove listeners anteriores para evitar duplica??o
      input.removeEventListener("input", this.handleColorInputChange)
      input.addEventListener("input", this.handleColorInputChange.bind(this))
    })
  }

  handleColorPickerChange(e) {
    const colorType = e.target.dataset.colorType
    const input = this.colorInputTargets.find(input => 
      input.dataset.colorType === colorType
    )
    if (input) {
      input.value = e.target.value.toUpperCase()
    }
  }

  handleColorInputChange(e) {
    const colorType = e.target.dataset.colorType
    const picker = this.colorPickerTargets.find(picker => 
      picker.dataset.colorType === colorType
    )
    if (picker && /^#[0-9A-Fa-f]{6}$/.test(e.target.value)) {
      picker.value = e.target.value.toUpperCase()
    }
  }
}
