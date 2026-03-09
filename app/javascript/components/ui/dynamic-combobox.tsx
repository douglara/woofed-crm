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
}

export interface DynamicComboboxProps {
  /** Current selected value (controlled) */
  value?: string | number | null;
  /** Callback when value changes */
  onChange?: (
    value: string | number | null,
    option?: DynamicComboboxOption,
  ) => void;
  /** Model name for the combobox controller (e.g., "user", "contact", "product") */
  modelName: string;
  /** Ransack search predicate (e.g., "full_name_or_email_cont") */
  ransackParam: string;
  /** Account ID for building the combobox search URL */
  accountId: number;
  /** Placeholder text */
  placeholder?: string;
  /** Debounce delay in ms */
  debounceMs?: number;
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
  /** Fetch initial results when combobox opens (default: true) */
  fetchOnOpen?: boolean;
}

function buildComboboxUrl(accountId: number, modelName: string): string {
  let url = `/inertia/accounts/${encodeURIComponent(accountId)}/components/combobox?model=${encodeURIComponent(modelName)}`;
  return url;
}

export function DynamicCombobox({
  value,
  onChange,
  modelName,
  ransackParam,
  accountId,
  placeholder = "Search...",
  debounceMs = 300,
  className,
  disabled = false,
  showClear = false,
  emptyMessage = "No results found.",
  loadingMessage = "Loading...",
  fetchOnOpen = true,
}: DynamicComboboxProps) {
  const [options, setOptions] = React.useState<DynamicComboboxOption[]>([]);
  const [isLoading, setIsLoading] = React.useState(false);
  const [inputValue, setInputValue] = React.useState("");
  const [error, setError] = React.useState<string | null>(null);
  const [hasFetched, setHasFetched] = React.useState(false);

  // Find selected option label for display
  const selectedOption = React.useMemo(() => {
    if (value === null || value === undefined) return null;
    return options.find((opt) => String(opt.value) === String(value)) || null;
  }, [value, options]);

  // Auto-fetch label for an initial value that has no matching option yet
  // (e.g., when filters are reconstructed from URL params)
  const initialFetchDone = React.useRef(false);
  React.useEffect(() => {
    if (
      value !== null &&
      value !== undefined &&
      !selectedOption &&
      !initialFetchDone.current
    ) {
      initialFetchDone.current = true;
      const url = new URL(
        buildComboboxUrl(accountId, modelName),
        window.location.origin,
      );
      url.searchParams.set("q[id_eq]", String(value));
      fetch(url.toString(), {
        method: "GET",
        headers: {
          Accept: "application/json",
          "X-Requested-With": "XMLHttpRequest",
        },
        credentials: "same-origin",
      })
        .then((res) => (res.ok ? res.json() : []))
        .then((data: DynamicComboboxOption[]) => {
          if (data.length > 0) {
            setOptions((prev) => {
              const existing = new Set(prev.map((p) => String(p.value)));
              const newOpts = data.filter(
                (d) => !existing.has(String(d.value)),
              );
              return newOpts.length > 0 ? [...prev, ...newOpts] : prev;
            });
          }
        })
        .catch(() => {
          // ignore - label just won't show
        });
    }
  }, [value, selectedOption, accountId, modelName]);

  const fetchOptions = React.useCallback(
    async (searchTerm: string, isInitialFetch = false) => {
      if (!isInitialFetch && searchTerm.length < 1) {
        setOptions([]);
        return;
      }

      setIsLoading(true);
      setError(null);
      setHasFetched(true);

      try {
        const url = new URL(
          buildComboboxUrl(accountId, modelName),
          window.location.origin,
        );
        if (searchTerm) {
          url.searchParams.set(`q[${ransackParam}]`, searchTerm);
        }

        const response = await fetch(url.toString(), {
          method: "GET",
          headers: {
            Accept: "application/json",
            "X-Requested-With": "XMLHttpRequest",
          },
          credentials: "same-origin",
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data: DynamicComboboxOption[] = await response.json();

        // Preserve the currently selected option in the list so its label
        // keeps showing even if the new results don't include it
        setOptions((prev) => {
          if (value === null || value === undefined) return data;
          const selectedInNew = data.some(
            (d) => String(d.value) === String(value),
          );
          if (selectedInNew) return data;
          const selectedOpt = prev.find(
            (p) => String(p.value) === String(value),
          );
          return selectedOpt ? [selectedOpt, ...data] : data;
        });
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
    [accountId, modelName, ransackParam, value],
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
