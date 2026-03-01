import * as React from "react"
import { flushSync } from "react-dom"
import { Check, ChevronsUpDown, Loader2 } from "lucide-react"

import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover"

export interface ModelComboboxItem {
  value: string
  label: string
}

export interface ModelComboboxProps {
  /** Model a ser buscado: "user", "contact", "product", "pipeline" */
  model_name: string
  /** Predicado Ransack, ex: full_name_or_email_cont */
  ransackParam: string
  /** Nome do campo hidden input no form, ex: filter[users_id_eq] */
  name: string
  selectedValue?: string
  selectedLabel?: string
  placeholder?: string
  allLabel?: string
  triggerClassName?: string
}

function buildSearchUrl(model_name: string): string {
  return `/inertia/components/combobox?model=${model_name}`
}

export default function ModelCombobox({
  model_name,
  ransackParam,
  name,
  selectedValue = "",
  selectedLabel = "",
  placeholder = "Buscar...",
  allLabel = "Todos",
  triggerClassName,
}: ModelComboboxProps) {
  const [open, setOpen] = React.useState(false)
  const [value, setValue] = React.useState(selectedValue)
  const [displayLabel, setDisplayLabel] = React.useState(
    selectedValue && selectedLabel ? selectedLabel : allLabel
  )
  const [query, setQuery] = React.useState("")
  const [items, setItems] = React.useState<ModelComboboxItem[]>([])
  const [loading, setLoading] = React.useState(false)
  const hiddenInputRef = React.useRef<HTMLInputElement>(null)

  React.useEffect(() => {
    if (!open) return

    let cancelled = false

    const timer = setTimeout(async () => {
      setLoading(true)
      try {
        const url = new URL(buildSearchUrl(model_name), window.location.origin)
        if (query) url.searchParams.set(`q[${ransackParam}]`, query)

        const response = await fetch(url.toString(), {
          headers: { Accept: "application/json" },
        })
        const data: ModelComboboxItem[] = await response.json()
        if (!cancelled) setItems(data)
      } catch {
        // ignore network errors
      } finally {
        if (!cancelled) setLoading(false)
      }
    }, query ? 300 : 0)

    return () => {
      cancelled = true
      clearTimeout(timer)
    }
  }, [open, query, model_name, ransackParam])

  const handleSelect = (newValue: string, newLabel: string) => {
    const next = newValue === value ? "" : newValue
    const nextLabel = next ? newLabel : allLabel

    flushSync(() => {
      setValue(next)
      setDisplayLabel(nextLabel)
      setOpen(false)
    })

    hiddenInputRef.current?.closest("form")?.requestSubmit()
  }

  const handleOpenChange = (next: boolean) => {
    setOpen(next)
    if (!next) setQuery("")
  }

  return (
    <>
      <input ref={hiddenInputRef} type="hidden" name={name} value={value} readOnly />
      <Popover open={open} onOpenChange={handleOpenChange}>
        <PopoverTrigger asChild>
          <Button
            variant="outline"
            role="combobox"
            aria-expanded={open}
            className={cn("w-full justify-between font-normal", triggerClassName)}
          >
            <span className="truncate">{displayLabel}</span>
            <ChevronsUpDown className="shrink-0 opacity-50" />
          </Button>
        </PopoverTrigger>
        <PopoverContent
          className="p-0"
          style={{ minWidth: "var(--radix-popover-trigger-width)" }}
        >
          <Command shouldFilter={false}>
            <CommandInput
              placeholder={placeholder}
              className="h-9"
              value={query}
              onValueChange={setQuery}
            />
            <CommandList>
              {loading ? (
                <div className="flex items-center justify-center py-4">
                  <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
                </div>
              ) : (
                <>
                  <CommandEmpty>Nenhum resultado encontrado.</CommandEmpty>
                  <CommandGroup>
                    <CommandItem
                      value={allLabel}
                      onSelect={() => handleSelect("", allLabel)}
                    >
                      {allLabel}
                      <Check
                        className={cn(
                          "ml-auto",
                          value === "" ? "opacity-100" : "opacity-0"
                        )}
                      />
                    </CommandItem>
                    {items.map((item) => (
                      <CommandItem
                        key={item.value}
                        value={item.value}
                        onSelect={() => handleSelect(item.value, item.label)}
                      >
                        {item.label}
                        <Check
                          className={cn(
                            "ml-auto",
                            value === item.value ? "opacity-100" : "opacity-0"
                          )}
                        />
                      </CommandItem>
                    ))}
                  </CommandGroup>
                </>
              )}
            </CommandList>
          </Command>
        </PopoverContent>
      </Popover>
    </>
  )
}
