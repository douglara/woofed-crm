/**
 * useSavedFilters Hook
 *
 * Manages saved filter configurations using localStorage.
 * Allows users to save, load, rename, and delete filter presets.
 */

import * as React from "react";
import { FilterGroup, SavedFilter } from "./types";

const STORAGE_KEY_PREFIX = "woofed_filters_";

interface UseSavedFiltersOptions {
  /** Resource name for namespacing saved filters */
  resource: string;
  /** Account ID for multi-tenant support */
  accountId?: number | string;
}

interface UseSavedFiltersReturn {
  /** List of saved filters for this resource */
  savedFilters: SavedFilter[];
  /** Save current filter with a name */
  saveFilter: (name: string, filterGroup: FilterGroup) => SavedFilter;
  /** Load a saved filter by ID */
  loadFilter: (id: string) => FilterGroup | null;
  /** Delete a saved filter by ID */
  deleteFilter: (id: string) => void;
  /** Rename a saved filter */
  renameFilter: (id: string, newName: string) => void;
  /** Update an existing saved filter */
  updateFilter: (id: string, filterGroup: FilterGroup) => void;
  /** Check if a filter name already exists */
  filterExists: (name: string) => boolean;
}

function generateFilterId(): string {
  return `filter_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

function getStorageKey(resource: string, accountId?: number | string): string {
  const accountPart = accountId ? `_${accountId}` : "";
  return `${STORAGE_KEY_PREFIX}${resource}${accountPart}`;
}

export function useSavedFilters(
  options: UseSavedFiltersOptions,
): UseSavedFiltersReturn {
  const { resource, accountId } = options;
  const storageKey = getStorageKey(resource, accountId);

  // Load saved filters from localStorage
  const [savedFilters, setSavedFilters] = React.useState<SavedFilter[]>(() => {
    if (typeof window === "undefined") {
      return [];
    }

    try {
      const stored = localStorage.getItem(storageKey);
      if (stored) {
        const parsed = JSON.parse(stored);
        return Array.isArray(parsed) ? parsed : [];
      }
    } catch {
      console.error("Failed to load saved filters from localStorage");
    }

    return [];
  });

  // Persist to localStorage whenever saved filters change
  React.useEffect(() => {
    if (typeof window === "undefined") return;

    try {
      localStorage.setItem(storageKey, JSON.stringify(savedFilters));
    } catch {
      console.error("Failed to save filters to localStorage");
    }
  }, [savedFilters, storageKey]);

  // Save a new filter
  const saveFilter = React.useCallback(
    (name: string, filterGroup: FilterGroup): SavedFilter => {
      const newFilter: SavedFilter = {
        id: generateFilterId(),
        name: name.trim(),
        filterGroup: structuredClone(filterGroup),
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      setSavedFilters((prev) => [...prev, newFilter]);
      return newFilter;
    },
    [],
  );

  // Load a saved filter by ID
  const loadFilter = React.useCallback(
    (id: string): FilterGroup | null => {
      const filter = savedFilters.find((f) => f.id === id);
      if (filter) {
        // Return a deep clone to prevent mutations
        return structuredClone(filter.filterGroup);
      }
      return null;
    },
    [savedFilters],
  );

  // Delete a saved filter by ID
  const deleteFilter = React.useCallback((id: string) => {
    setSavedFilters((prev) => prev.filter((f) => f.id !== id));
  }, []);

  // Rename a saved filter
  const renameFilter = React.useCallback((id: string, newName: string) => {
    setSavedFilters((prev) =>
      prev.map((f) =>
        f.id === id
          ? { ...f, name: newName.trim(), updatedAt: new Date().toISOString() }
          : f,
      ),
    );
  }, []);

  // Update an existing saved filter
  const updateFilter = React.useCallback(
    (id: string, filterGroup: FilterGroup) => {
      setSavedFilters((prev) =>
        prev.map((f) =>
          f.id === id
            ? {
                ...f,
                filterGroup: structuredClone(filterGroup),
                updatedAt: new Date().toISOString(),
              }
            : f,
        ),
      );
    },
    [],
  );

  // Check if a filter name already exists
  const filterExists = React.useCallback(
    (name: string): boolean => {
      const trimmedName = name.trim().toLowerCase();
      return savedFilters.some((f) => f.name.toLowerCase() === trimmedName);
    },
    [savedFilters],
  );

  return {
    savedFilters,
    saveFilter,
    loadFilter,
    deleteFilter,
    renameFilter,
    updateFilter,
    filterExists,
  };
}

// ============================================================================
// SavedFiltersDropdown Component
// ============================================================================

interface SavedFiltersDropdownProps {
  /** Resource name */
  resource: string;
  /** Account ID for multi-tenant support */
  accountId?: number | string;
  /** Current filter group */
  currentFilter: FilterGroup;
  /** Callback when a saved filter is loaded */
  onLoad: (filterGroup: FilterGroup) => void;
  /** Class name */
  className?: string;
}

export function SavedFiltersDropdown({
  resource,
  accountId,
  currentFilter,
  onLoad,
  className,
}: SavedFiltersDropdownProps) {
  const { savedFilters, saveFilter, loadFilter, deleteFilter, filterExists } =
    useSavedFilters({ resource, accountId });

  const [isOpen, setIsOpen] = React.useState(false);
  const [isSaving, setIsSaving] = React.useState(false);
  const [newFilterName, setNewFilterName] = React.useState("");
  const [error, setError] = React.useState<string | null>(null);

  const dropdownRef = React.useRef<HTMLDivElement>(null);

  // Close dropdown when clicking outside
  React.useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
        setIsSaving(false);
        setNewFilterName("");
        setError(null);
      }
    }

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleSave = () => {
    if (!newFilterName.trim()) {
      setError("Please enter a filter name");
      return;
    }

    if (filterExists(newFilterName)) {
      setError("A filter with this name already exists");
      return;
    }

    saveFilter(newFilterName, currentFilter);
    setNewFilterName("");
    setIsSaving(false);
    setError(null);
  };

  const handleLoad = (id: string) => {
    const filterGroup = loadFilter(id);
    if (filterGroup) {
      onLoad(filterGroup);
      setIsOpen(false);
    }
  };

  const handleDelete = (e: React.MouseEvent, id: string) => {
    e.stopPropagation();
    deleteFilter(id);
  };

  // Check if current filter has any conditions
  const hasConditions =
    currentFilter.conditions.length > 0 &&
    currentFilter.conditions.some((c) => "field" in c && c.field && c.operator);

  return (
    <div ref={dropdownRef} className={`relative ${className || ""}`}>
      {/* Toggle Button */}
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="inline-flex items-center gap-2 rounded-md border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
      >
        <svg
          className="h-4 w-4"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
          />
        </svg>
        Saved Filters
        {savedFilters.length > 0 && (
          <span className="rounded-full bg-blue-100 px-2 py-0.5 text-xs text-blue-700">
            {savedFilters.length}
          </span>
        )}
      </button>

      {/* Dropdown */}
      {isOpen && (
        <div className="absolute left-0 top-full z-50 mt-1 w-64 rounded-md border border-gray-200 bg-white shadow-lg">
          {/* Saved Filters List */}
          <div className="max-h-64 overflow-y-auto">
            {savedFilters.length === 0 ? (
              <div className="p-3 text-center text-sm text-gray-500">
                No saved filters yet
              </div>
            ) : (
              savedFilters.map((filter) => (
                <div
                  key={filter.id}
                  onClick={() => handleLoad(filter.id)}
                  className="flex cursor-pointer items-center justify-between px-3 py-2 hover:bg-gray-50"
                >
                  <div>
                    <div className="text-sm font-medium text-gray-900">
                      {filter.name}
                    </div>
                    <div className="text-xs text-gray-500">
                      {new Date(filter.updatedAt).toLocaleDateString()}
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={(e) => handleDelete(e, filter.id)}
                    className="rounded p-1 text-gray-400 hover:bg-gray-200 hover:text-red-500"
                  >
                    <svg
                      className="h-4 w-4"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M6 18L18 6M6 6l12 12"
                      />
                    </svg>
                  </button>
                </div>
              ))
            )}
          </div>

          {/* Divider */}
          <div className="border-t border-gray-200" />

          {/* Save New Filter */}
          {isSaving ? (
            <div className="p-3">
              <input
                type="text"
                value={newFilterName}
                onChange={(e) => {
                  setNewFilterName(e.target.value);
                  setError(null);
                }}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    handleSave();
                  } else if (e.key === "Escape") {
                    setIsSaving(false);
                    setNewFilterName("");
                    setError(null);
                  }
                }}
                placeholder="Filter name..."
                className="w-full rounded-md border border-gray-300 px-2 py-1 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                autoFocus
              />
              {error && (
                <div className="mt-1 text-xs text-red-500">{error}</div>
              )}
              <div className="mt-2 flex gap-2">
                <button
                  type="button"
                  onClick={handleSave}
                  className="flex-1 rounded-md bg-blue-600 px-2 py-1 text-sm text-white hover:bg-blue-700"
                >
                  Save
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setIsSaving(false);
                    setNewFilterName("");
                    setError(null);
                  }}
                  className="flex-1 rounded-md border border-gray-300 px-2 py-1 text-sm text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
              </div>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setIsSaving(true)}
              disabled={!hasConditions}
              className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm text-blue-600 hover:bg-gray-50 disabled:cursor-not-allowed disabled:text-gray-400"
            >
              <svg
                className="h-4 w-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                />
              </svg>
              Save current filter
            </button>
          )}
        </div>
      )}
    </div>
  );
}
