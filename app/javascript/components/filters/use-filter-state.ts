/**
 * useFilterState Hook
 *
 * Manages the state of dynamic filters and provides methods
 * for manipulating conditions and groups.
 */

import * as React from "react";
import { router } from "@inertiajs/react";
import {
  FilterGroup,
  FilterCondition,
  FilterField,
  LogicOperator,
  RansackQuery,
  createEmptyCondition,
  createEmptyGroup,
  isFilterGroup,
  isFilterCondition,
} from "./types";
import {
  buildRansackQuery,
  parseRansackParams,
  serializeToUrlParams,
} from "./ransack-builder";

interface UseFilterStateOptions {
  /** Initial filter group */
  initialFilters?: FilterGroup;
  /** Available fields */
  fields: FilterField[];
  /** Base URL for navigation */
  baseUrl?: string;
  /** URL to redirect to with filter params (for drawer-based filter pages) */
  redirectUrl?: string;
  /** Callback when filters change */
  onChange?: (group: FilterGroup) => void;
}

interface UseFilterStateReturn {
  /** Current filter group */
  filterGroup: FilterGroup;
  /** Set the entire filter group */
  setFilterGroup: React.Dispatch<React.SetStateAction<FilterGroup>>;
  /** Add a new condition to a group */
  addCondition: (groupId?: string) => void;
  /** Remove a condition by ID */
  removeCondition: (conditionId: string) => void;
  /** Update a condition */
  updateCondition: (
    conditionId: string,
    updates: Partial<FilterCondition>,
  ) => void;
  /** Add a nested group */
  addGroup: (parentGroupId?: string, logic?: LogicOperator) => void;
  /** Remove a group by ID */
  removeGroup: (groupId: string) => void;
  /** Toggle logic operator for a group */
  toggleLogic: (groupId?: string) => void;
  /** Set logic operator for a group */
  setLogic: (groupId: string, logic: LogicOperator) => void;
  /** Build Ransack query from current state */
  buildQuery: () => RansackQuery;
  /** Apply filters (navigate with query params) */
  applyFilters: () => void;
  /** Clear all filters */
  clearFilters: () => void;
  /** Check if filters have changed */
  hasFilters: boolean;
  /** Get filter count */
  filterCount: number;
  /** Parse filters from URL */
  parseFromUrl: () => void;
}

export function useFilterState(
  options: UseFilterStateOptions,
): UseFilterStateReturn {
  const {
    initialFilters,
    fields: _fields,
    baseUrl,
    redirectUrl,
    onChange,
  } = options;

  // Initialize filter group
  const [filterGroup, setFilterGroup] = React.useState<FilterGroup>(() => {
    if (initialFilters) {
      return initialFilters;
    }
    // Try to parse from URL
    if (typeof window !== "undefined") {
      const params = new URLSearchParams(window.location.search);
      const parsed = parseRansackParams(params);
      if (parsed.conditions.length > 0) {
        return parsed;
      }
    }
    return createEmptyGroup();
  });

  // Notify on change
  React.useEffect(() => {
    onChange?.(filterGroup);
  }, [filterGroup, onChange]);

  // Find a group by ID (recursive)
  const findGroup = React.useCallback(
    (group: FilterGroup, groupId: string): FilterGroup | null => {
      if (group.id === groupId) {
        return group;
      }
      for (const item of group.conditions) {
        if (isFilterGroup(item)) {
          const found = findGroup(item, groupId);
          if (found) return found;
        }
      }
      return null;
    },
    [],
  );

  // Find parent group of an item
  const findParentGroup = React.useCallback(
    (group: FilterGroup, itemId: string): FilterGroup | null => {
      for (const item of group.conditions) {
        if (
          (isFilterCondition(item) || isFilterGroup(item)) &&
          item.id === itemId
        ) {
          return group;
        }
        if (isFilterGroup(item)) {
          const found = findParentGroup(item, itemId);
          if (found) return found;
        }
      }
      return null;
    },
    [],
  );

  // Add condition
  const addCondition = React.useCallback(
    (groupId?: string) => {
      setFilterGroup((prev) => {
        const newGroup = deepClone(prev);
        const targetGroup = groupId ? findGroup(newGroup, groupId) : newGroup;

        if (targetGroup) {
          targetGroup.conditions.push(createEmptyCondition());
        }

        return newGroup;
      });
    },
    [findGroup],
  );

  // Remove condition
  const removeCondition = React.useCallback(
    (conditionId: string) => {
      setFilterGroup((prev) => {
        const newGroup = deepClone(prev);
        const parentGroup = findParentGroup(newGroup, conditionId);

        if (parentGroup) {
          parentGroup.conditions = parentGroup.conditions.filter(
            (item) => item.id !== conditionId,
          );

          // Ensure at least one condition remains in root
          if (
            parentGroup.id === newGroup.id &&
            parentGroup.conditions.length === 0
          ) {
            parentGroup.conditions.push(createEmptyCondition());
          }
        }

        return newGroup;
      });
    },
    [findParentGroup],
  );

  // Update condition
  const updateCondition = React.useCallback(
    (conditionId: string, updates: Partial<FilterCondition>) => {
      setFilterGroup((prev) => {
        const newGroup = deepClone(prev);

        const updateInGroup = (group: FilterGroup): boolean => {
          for (let i = 0; i < group.conditions.length; i++) {
            const item = group.conditions[i];
            if (isFilterCondition(item) && item.id === conditionId) {
              group.conditions[i] = { ...item, ...updates };
              return true;
            }
            if (isFilterGroup(item)) {
              if (updateInGroup(item)) return true;
            }
          }
          return false;
        };

        updateInGroup(newGroup);
        return newGroup;
      });
    },
    [],
  );

  // Add nested group
  const addGroup = React.useCallback(
    (parentGroupId?: string, logic: LogicOperator = "and") => {
      setFilterGroup((prev) => {
        const newGroup = deepClone(prev);
        const targetGroup = parentGroupId
          ? findGroup(newGroup, parentGroupId)
          : newGroup;

        if (targetGroup) {
          const nestedGroup = createEmptyGroup(logic);
          targetGroup.conditions.push(nestedGroup);
        }

        return newGroup;
      });
    },
    [findGroup],
  );

  // Remove group
  const removeGroup = React.useCallback(
    (groupId: string) => {
      setFilterGroup((prev) => {
        const newGroup = deepClone(prev);
        const parentGroup = findParentGroup(newGroup, groupId);

        if (parentGroup) {
          parentGroup.conditions = parentGroup.conditions.filter(
            (item) => item.id !== groupId,
          );
        }

        return newGroup;
      });
    },
    [findParentGroup],
  );

  // Toggle logic
  const toggleLogic = React.useCallback(
    (groupId?: string) => {
      setFilterGroup((prev) => {
        const newGroup = deepClone(prev);
        const targetGroup = groupId ? findGroup(newGroup, groupId) : newGroup;

        if (targetGroup) {
          targetGroup.logic = targetGroup.logic === "and" ? "or" : "and";
        }

        return newGroup;
      });
    },
    [findGroup],
  );

  // Set logic
  const setLogic = React.useCallback(
    (groupId: string, logic: LogicOperator) => {
      setFilterGroup((prev) => {
        const newGroup = deepClone(prev);
        const targetGroup = findGroup(newGroup, groupId);

        if (targetGroup) {
          targetGroup.logic = logic;
        }

        return newGroup;
      });
    },
    [findGroup],
  );

  // Build query
  const buildQuery = React.useCallback(() => {
    return buildRansackQuery(filterGroup);
  }, [filterGroup]);

  // Apply filters
  const applyFilters = React.useCallback(() => {
    const params = serializeToUrlParams(filterGroup);
    const queryString = params.toString();

    // If redirectUrl is set, redirect back to the original page with filter params
    if (redirectUrl) {
      // Strip existing query[...] params from redirectUrl to avoid duplication
      const urlObj = new URL(redirectUrl, window.location.origin);
      const keysToDelete: string[] = [];
      urlObj.searchParams.forEach((_v, key) => {
        if (key.startsWith("filter[")) {
          keysToDelete.push(key);
        }
      });
      keysToDelete.forEach((key) => urlObj.searchParams.delete(key));

      const cleanUrl = urlObj.pathname + (urlObj.search ? urlObj.search : "");
      const separator = cleanUrl.includes("?") ? "&" : "?";
      const url = queryString
        ? `${cleanUrl}${separator}${queryString}`
        : cleanUrl;
      window.location.href = url;
      return;
    }

    if (baseUrl) {
      const url = queryString ? `${baseUrl}?${queryString}` : baseUrl;

      router.visit(url, {
        preserveState: true,
        preserveScroll: true,
      });
    }
  }, [filterGroup, baseUrl, redirectUrl]);

  // Clear filters
  const clearFilters = React.useCallback(() => {
    const emptyGroup = createEmptyGroup();
    setFilterGroup(emptyGroup);

    // When redirectUrl is set (drawer mode), just clear the UI state.
    // The user can click "Apply Filters" to commit the cleared state.
    if (redirectUrl) {
      return;
    }

    if (baseUrl) {
      router.visit(baseUrl, {
        preserveState: true,
        preserveScroll: true,
      });
    }
  }, [baseUrl, redirectUrl]);

  // Parse from URL
  const parseFromUrl = React.useCallback(() => {
    if (typeof window !== "undefined") {
      const params = new URLSearchParams(window.location.search);
      const parsed = parseRansackParams(params);
      if (parsed.conditions.length > 0) {
        setFilterGroup(parsed);
      }
    }
  }, []);

  // Count valid filters
  const filterCount = React.useMemo(() => {
    let count = 0;

    const countInGroup = (group: FilterGroup) => {
      for (const item of group.conditions) {
        if (isFilterCondition(item) && item.field && item.operator) {
          count++;
        }
        if (isFilterGroup(item)) {
          countInGroup(item);
        }
      }
    };

    countInGroup(filterGroup);
    return count;
  }, [filterGroup]);

  // Check if has filters
  const hasFilters = filterCount > 0;

  return {
    filterGroup,
    setFilterGroup,
    addCondition,
    removeCondition,
    updateCondition,
    addGroup,
    removeGroup,
    toggleLogic,
    setLogic,
    buildQuery,
    applyFilters,
    clearFilters,
    hasFilters,
    filterCount,
    parseFromUrl,
  };
}

// Helper to deep clone
function deepClone<T>(obj: T): T {
  return JSON.parse(JSON.stringify(obj));
}

export default useFilterState;
