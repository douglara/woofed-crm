import * as React from "react"
import { router, usePage } from "@inertiajs/react"
import {
  Combobox,
  ComboboxContent,
  ComboboxEmpty,
  ComboboxInput,
  ComboboxItem,
  ComboboxList,
} from "@/components/ui/combobox"

interface User {
  id: number
  full_name: string
}

interface PageProps {
  users: User[]
  selected_user_id: number | null
  input_name: string
  placeholder: string
  form_id: string | null
}

export default function ComboboxSelect() {
  const { users, selected_user_id, input_name, placeholder, form_id } = usePage<PageProps>().props

  const [selectedValue, setSelectedValue] = React.useState<string | null>(
    selected_user_id ? String(selected_user_id) : null
  )
  const [inputValue, setInputValue] = React.useState("")

  const selectedUser = users.find(user => String(user.id) === selectedValue)

  const handleValueChange = (value: string | null) => {
    setSelectedValue(value)

    // Submit the form if form_id is provided
    if (form_id) {
      const form = document.getElementById(form_id) as HTMLFormElement
      if (form) {
        // Create a hidden input with the selected value
        const existingInput = form.querySelector(`input[name="${input_name}"]`) as HTMLInputElement
        if (existingInput) {
          existingInput.value = value || ""
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

  return (
    <div className="w-full">
      <input type="hidden" name={input_name} value={selectedValue || ""} />
      <Combobox
        value={selectedValue}
        onValueChange={handleValueChange}
        onInputValueChange={setInputValue}
      >
        <ComboboxInput
          placeholder={placeholder}
          className="form-input border-solid border-2 color-border-default rounded-r-md rounded-l-none flex-1 h-10 ml-[-2px] hover:border-gray-400 hover:z-10 hover:cursor-pointer focus:border-gray-400 focus:ring-0 focus:z-10"
        />
        <ComboboxContent>
          <ComboboxEmpty>Nenhum usuário encontrado.</ComboboxEmpty>
          <ComboboxList>
            {filteredUsers.map((user) => (
              <ComboboxItem key={user.id} value={String(user.id)}>
                {user.full_name}
              </ComboboxItem>
            ))}
          </ComboboxList>
        </ComboboxContent>
      </Combobox>
    </div>
  )
}
