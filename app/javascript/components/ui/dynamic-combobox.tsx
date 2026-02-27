"use client";

import * as React from "react";

import {
  Combobox,
  ComboboxInput,
  ComboboxContent,
  ComboboxItem,
  ComboboxList,
} from "@/components/ui/combobox";

// Simple debounce hook
function useDebouncedCallback<T extends (...args: Parameters<T>) => void>(
  callback: T,
  delay: number,
): T {
  const timeoutRef = React.useRef<ReturnType<typeof setTimeout> | null>(null);
  const callbackRef = React.useRef(callback);

  React.useEffect(() => {
    callbackRef.current = callback;
  }, [callback]);

  React.useEffect(() => {
    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, []);

  return React.useCallback(
    ((...args: Parameters<T>) => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
      timeoutRef.current = setTimeout(() => {
        callbackRef.current(...args);
      }, delay);
    }) as T,
    [delay],
  );
}

export interface DynamicComboboxOption {
  value: string | number;
  label: string;
  [key: string]: unknown;
}

export interface DynamicComboboxProps {
  /** Current selected value (controlled) */
  value?: string | number | null;
  /** Callback when value changes */
  onChange?: (
    value: string | number | null,
    option?: DynamicComboboxOption,
  ) => void;
  /** API endpoint to fetch options (e.g., "/inertia/accounts/1/contacts/search") */
  endpoint: string;
  /** Ransack search key (e.g., "full_name_cont" or "email_or_full_name_cont") */
  searchKey?: string;
  /** Key in response object to use as label (e.g., "full_name") */
  labelKey?: string;
  /** Key in response object to use as value (e.g., "id") */
  valueKey?: string;
  /** Placeholder text */
  placeholder?: string;
  /** Minimum characters to trigger search */
  minChars?: number;
  /** Debounce delay in ms */
  debounceMs?: number;
  /** Initial options to display */
  initialOptions?: DynamicComboboxOption[];
  /** Additional className for the input */
  className?: string;
  /** Disabled state */
  disabled?: boolean;
  /** Show clear button */
  showClear?: boolean;
  /** Empty state message */
  emptyMessage?: string;
  /** Loading state message */
  loadingMessage?: string;
  /** Transform response data (useful for nested responses) */
  transformResponse?: (data: unknown) => unknown[];
  /** Fetch initial results when combobox opens (default: true) */
  fetchOnOpen?: boolean;
}

export function DynamicCombobox({
  value,
  onChange,
  endpoint,
  searchKey = "full_name_cont",
  labelKey = "full_name",
  valueKey = "id",
  placeholder = "Search...",
  minChars = 1,
  debounceMs = 300,
  initialOptions = [],
  className,
  disabled = false,
  showClear = false,
  emptyMessage = "No results found.",
  loadingMessage = "Loading...",
  transformResponse,
  fetchOnOpen = true,
}: DynamicComboboxProps) {
  const [options, setOptions] =
    React.useState<DynamicComboboxOption[]>(initialOptions);
  const [isLoading, setIsLoading] = React.useState(false);
  const [inputValue, setInputValue] = React.useState("");
  const [error, setError] = React.useState<string | null>(null);
  const [hasFetched, setHasFetched] = React.useState(false);

  // Find selected option label for display
  const selectedOption = React.useMemo(() => {
    if (value === null || value === undefined) return null;
    return options.find((opt) => String(opt.value) === String(value)) || null;
  }, [value, options]);

  const fetchOptions = React.useCallback(
    async (searchTerm: string, isInitialFetch = false) => {
      // Allow initial fetch or typed search that meets minChars
      if (!isInitialFetch && searchTerm.length < minChars) {
        setOptions(initialOptions);
        return;
      }

      setIsLoading(true);
      setError(null);
      setHasFetched(true);

      try {
        // Build ransack query params
        const params = new URLSearchParams();
        params.set(`query[${searchKey}]`, searchTerm);

        const response = await fetch(`${endpoint}?${params.toString()}`, {
          method: "GET",
          headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
            "X-Requested-With": "XMLHttpRequest",
          },
          credentials: "same-origin",
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const result = await response.json();

        // Transform response if transformer provided, otherwise use data directly
        let items: unknown[];
        if (transformResponse) {
          items = transformResponse(result);
        } else if (Array.isArray(result.data)) {
          items = result.data;
        } else if (Array.isArray(result)) {
          items = result;
        } else {
          items = [];
        }

        // Map to options format
        const mappedOptions: DynamicComboboxOption[] = (
          items as Record<string, unknown>[]
        ).map((item) => ({
          value: item[valueKey] as string | number,
          label: item[labelKey] as string,
          ...item,
        }));

        setOptions(mappedOptions);
      } catch (err) {
        console.error("DynamicCombobox fetch error:", err);
        setError(
          err instanceof Error ? err.message : "Failed to fetch options",
        );
        setOptions([]);
      } finally {
        setIsLoading(false);
      }
    },
    [
      endpoint,
      searchKey,
      labelKey,
      valueKey,
      minChars,
      initialOptions,
      transformResponse,
    ],
  );

  const debouncedFetch = useDebouncedCallback(fetchOptions, debounceMs);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;
    setInputValue(newValue);

    // When input is cleared completely, treat as initial fetch to show all items
    if (newValue === "") {
      fetchOptions("", true);
    } else {
      debouncedFetch(newValue);
    }
  };

  const handleValueChange = (newValue: string | null) => {
    const option = options.find(
      (opt) => String(opt.value) === String(newValue),
    );
    // Clear input value so displayValue shows the selected option's label
    setInputValue("");
    onChange?.(newValue ? (option?.value ?? newValue) : null, option);
  };

  // Determine what to show in input
  const displayValue = React.useMemo(() => {
    if (inputValue) return inputValue;
    if (selectedOption) return selectedOption.label;
    return "";
  }, [inputValue, selectedOption]);

  return (
    <Combobox
      value={value !== null && value !== undefined ? String(value) : ""}
      onValueChange={handleValueChange}
      filter={null} // Disable client-side filtering - we do server-side filtering
    >
      <ComboboxInput
        placeholder={placeholder}
        className={className}
        disabled={disabled}
        showClear={showClear}
        value={displayValue}
        onChange={handleInputChange}
        onFocus={() => {
          // Fetch initial results on focus if fetchOnOpen is enabled and no fetch has been done
          if (fetchOnOpen && !hasFetched && inputValue === "") {
            fetchOptions("", true);
          }
        }}
      />
      <ComboboxContent>
        {isLoading ? (
          <div className="py-2 text-center text-sm text-muted-foreground">
            {loadingMessage}
          </div>
        ) : error ? (
          <div className="py-2 text-center text-sm text-destructive">
            {error}
          </div>
        ) : (
          <>
            {/* Only show empty message when we have fetched and truly have no options */}
            {hasFetched && options.length === 0 && (
              <div className="py-2 text-center text-sm text-muted-foreground">
                {emptyMessage}
              </div>
            )}
            <ComboboxList>
              {options.map((option) => (
                <ComboboxItem
                  key={String(option.value)}
                  value={String(option.value)}
                >
                  {option.label}
                </ComboboxItem>
              ))}
            </ComboboxList>
          </>
        )}
      </ComboboxContent>
    </Combobox>
  );
}

export default DynamicCombobox;
