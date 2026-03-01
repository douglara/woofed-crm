import { Controller } from "@hotwired/stimulus"
import { createElement } from "react"
import { createRoot } from "react-dom/client"
import ModelCombobox from "@/components/ui/model_combobox"

export default class extends Controller {
  static values = {
    modelName: String,
    ransackParam: String,
    name: String,
    selectedValue: { type: String, default: "" },
    selectedLabel: { type: String, default: "" },
    placeholder: { type: String, default: "Buscar..." },
    allLabel: { type: String, default: "Todos" },
    triggerClass: { type: String, default: "" },
  }

  connect() {
    this.root = createRoot(this.element)
    this._render()
  }

  disconnect() {
    this.root?.unmount()
  }

  _render() {
    this.root.render(
      createElement(ModelCombobox, {
        model_name: this.modelNameValue,
        ransackParam: this.ransackParamValue,
        name: this.nameValue,
        selectedValue: this.selectedValueValue,
        selectedLabel: this.selectedLabelValue,
        placeholder: this.placeholderValue,
        allLabel: this.allLabelValue,
        triggerClassName: this.triggerClassValue || undefined,
      })
    )
  }
}
