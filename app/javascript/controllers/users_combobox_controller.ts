import { Controller } from "@hotwired/stimulus"
import type { Root } from "react-dom/client"

interface User {
  id: number | null
  full_name: string
}

/*
 * Stimulus controller to mount the UsersCombobox React component.
 *
 * Usage:
 *   <div data-controller="users-combobox"
 *        data-users-combobox-users-value='[{"id": null, "full_name": "All"}, {"id": 1, "full_name": "John"}]'
 *        data-users-combobox-selected-user-id-value="1"
 *        data-users-combobox-input-name-value="filter[users_id_eq]"
 *        data-users-combobox-placeholder-value="Select a user"
 *        data-users-combobox-form-id-value="my-form">
 *   </div>
 */
export default class extends Controller<HTMLElement> {
  static values = {
    users: Array,
    selectedUserId: Number,
    inputName: String,
    placeholder: String,
    formId: String,
  }

  declare usersValue: User[]
  declare selectedUserIdValue: number | null
  declare inputNameValue: string
  declare placeholderValue: string
  declare formIdValue: string

  declare hasUsersValue: boolean
  declare hasSelectedUserIdValue: boolean
  declare hasInputNameValue: boolean
  declare hasPlaceholderValue: boolean
  declare hasFormIdValue: boolean

  private root: Root | null = null

  connect() {
    this.renderComponent()
  }

  disconnect() {
    if (this.root) {
      this.root.unmount()
      this.root = null
    }
  }

  usersValueChanged() {
    this.renderComponent()
  }

  selectedUserIdValueChanged() {
    this.renderComponent()
  }

  private async renderComponent() {
    const [{ createRoot }, { createElement }, { UsersCombobox }] = await Promise.all([
      import("react-dom/client"),
      import("react"),
      import("@/components/users/UsersCombobox"),
    ])

    if (!this.root) {
      this.root = createRoot(this.element)
    }

    const props = {
      users: this.hasUsersValue ? this.usersValue : [],
      selectedUserId: this.hasSelectedUserIdValue ? this.selectedUserIdValue : null,
      inputName: this.hasInputNameValue ? this.inputNameValue : "user_id",
      placeholder: this.hasPlaceholderValue ? this.placeholderValue : "Select a user",
      formId: this.hasFormIdValue ? this.formIdValue : null,
      className: "w-full",
    }

    this.root.render(createElement(UsersCombobox, props))
  }
}
