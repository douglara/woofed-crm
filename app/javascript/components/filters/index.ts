/**
 * Dynamic Filter System
 *
 * A global, reusable filter system inspired by Motor Admin.
 * Generates Ransack-compatible query parameters for any Rails model.
 *
 * Usage:
 * ```tsx
 * import { DynamicFilter, FilterField } from '@/components/filters';
 *
 * const fields: FilterField[] = [
 *   { name: 'name', label: 'Name', type: 'string' },
 *   { name: 'status', label: 'Status', type: 'select', options: [...] },
 *   { name: 'amount', label: 'Amount', type: 'decimal' },
 *   { name: 'created_at', label: 'Created At', type: 'date' },
 * ];
 *
 * <DynamicFilter
 *   resource="deals"
 *   fields={fields}
 *   baseUrl={`/accounts/${accountId}/deals`}
 *   onApply={(query) => console.log(query)}
 * />
 * ```
 */

// Components
export { DynamicFilter } from "./dynamic-filter";
export { FilterItem } from "./filter-item";

// Hooks
export { useFilterState } from "./use-filter-state";
export { useSavedFilters, SavedFiltersDropdown } from "./use-saved-filters";

// Utilities
export {
  buildRansackQuery,
  parseRansackParams,
  parseRansackQuery,
  serializeToUrlParams,
  buildQueryString,
} from "./ransack-builder";

// Types
export type {
  FilterField,
  FilterCondition,
  FilterGroup,
  FilterState,
  FieldType,
  FieldOption,
  OperatorKey,
  Operator,
  LogicOperator,
  RansackQuery,
  RansackConditions,
  RelationMeta,
  DynamicFilterProps,
  FilterItemProps,
  FilterGroupProps,
  SavedFilter,
} from "./types";

export {
  OPERATORS,
  OPERATORS_BY_TYPE,
  getOperatorsForField,
  isFilterGroup,
  isFilterCondition,
  generateId,
  createEmptyCondition,
  createEmptyGroup,
} from "./types";
