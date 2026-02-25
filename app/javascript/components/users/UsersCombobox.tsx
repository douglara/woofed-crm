import * as React from "react"
import {
  Combobox,
  ComboboxContent,
  ComboboxEmpty,
  ComboboxInput,
  ComboboxItem,
  ComboboxList,
} from "@/components/ui/combobox"

interface User {
  id: number | null
  full_name: string
}

interface UsersComboboxProps {
  users: User[]
  selectedUserId: number | null
  inputName: string
  placeholder: string
  formId: string | null
  onSelect?: (userId: number | null) => void
  className?: string
}

export function UsersCombobox({
  users,
  selectedUserId,
  inputName,
  placeholder,
  formId,
  onSelect,
  className,
}: UsersComboboxProps) {
  const [selectedValue, setSelectedValue] = React.useState<string | null>(
    selectedUserId !== null ? String(selectedUserId) : null
  )
  const [inputValue, setInputValue] = React.useState("")

  const handleValueChange = (value: string | null) => {
    setSelectedValue(value)

    if (onSelect) {
      onSelect(value ? parseInt(value, 10) : null)
    }

    // Submit the form if form_id is provided
    if (formId) {
      const form = document.getElementById(formId) as HTMLFormElement
      if (form) {
        // Update hidden input
        const hiddenInput = form.querySelector(`input[name="${inputName}"]`) as HTMLInputElement
        if (hiddenInput) {
          hiddenInput.value = value || ""
        }
        form.requestSubmit()
      }
    }
  }

  // Filter users based on input
  const filteredUsers = React.useMemo(() => {
    if (!inputValue) return users
    return users.filter(user =>
      user.full_name.toLowerCase().includes(inputValue.toLowerCase())
    )
  }, [users, inputValue])

  // Get display value for the selected user
  const selectedUser = users.find(user =>
    user.id !== null ? String(user.id) === selectedValue : selectedValue === null || selectedValue === ""
  )

  return (
    <div className={className}>
      <input type="hidden" name={inputName} value={selectedValue || ""} />
      <Combobox
        value={selectedValue}
        onValueChange={handleValueChange}
        onInputValueChange={setInputValue}
      >
        <ComboboxInput
          placeholder={selectedUser?.full_name || placeholder}
          className="form-input border-solid border-2 color-border-default rounded-r-md rounded-l-none flex-1 h-10 ml-[-2px] hover:border-gray-400 hover:z-10 hover:cursor-pointer focus:border-gray-400 focus:ring-0 focus:z-10 w-full"
        />
        <ComboboxContent>
          <ComboboxEmpty>Nenhum usuário encontrado.</ComboboxEmpty>
          <ComboboxList>
            {filteredUsers.map((user, index) => (
              <ComboboxItem
                key={user.id !== null ? user.id : `all-${index}`}
                value={user.id !== null ? String(user.id) : ""}
              >
                {user.full_name}
              </ComboboxItem>
            ))}
          </ComboboxList>
        </ComboboxContent>
      </Combobox>
    </div>
  )
}

export default UsersCombobox
