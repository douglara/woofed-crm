/**
 * Dynamic Filter System - Type Definitions
 *
 * This system generates Ransack-compatible query parameters
 * for filtering any model in the application.
 */

// ============================================================================
// Field Types
// ============================================================================

export type FieldType =
  | "string"
  | "text"
  | "number"
  | "integer"
  | "float"
  | "decimal"
  | "boolean"
  | "date"
  | "datetime"
  | "select"
  | "relation"
  | "reference";

export interface FieldOption {
  value: string | number | boolean;
  label: string;
}

/** Relation metadata for dynamic combobox lookups */
export interface RelationMeta {
  /** Target model name (e.g., "User") */
  model: string;
  /** Lowercase model name for combobox controller (e.g., "user") */
  modelName: string;
  /** Field to display as label (e.g., 'full_name') */
  labelKey: string;
  /** Field to use as value (e.g., 'id') */
  valueKey: string;
  /** Ransack search key (e.g., 'full_name_or_email_cont') */
  searchKey?: string;
}

export interface FilterField {
  /** Field name (e.g., 'name', 'status', 'contact_email') */
  name: string;
  /** Display label */
  label: string;
  /** Field data type */
  type: FieldType;
  /** Options for select fields */
  options?: FieldOption[];
  /** Relation metadata for FK fields */
  relation?: RelationMeta;
  /** Reference model name for associations (legacy) */
  reference?: {
    model: string;
    displayKey: string;
    valueKey: string;
    searchEndpoint?: string;
  };
  /** Whether field is from an association */
  association?: string;
}

// ============================================================================
// Operator Types
// ============================================================================

export type OperatorKey =
  // String operators
  | "eq"
  | "not_eq"
  | "cont"
  | "not_cont"
  | "start"
  | "end"
  | "matches"
  // Numeric operators
  | "gt"
  | "gteq"
  | "lt"
  | "lteq"
  // Null operators
  | "null"
  | "not_null"
  | "present"
  | "blank"
  // Array operators
  | "in"
  | "not_in";

export interface Operator {
  key: OperatorKey;
  label: string;
  /** Whether this operator requires a value input */
  requiresValue: boolean;
  /** Ransack suffix (e.g., '_cont', '_eq') */
  ransackSuffix: string;
}

// ============================================================================
// Filter Condition
// ============================================================================

export interface FilterCondition {
  id: string;
  /** Field name */
  field: string;
  /** Operator key */
  operator: OperatorKey;
  /** Filter value */
  value: string | number | boolean | null | (string | number)[];
  /** Display label for relation values (for showing name instead of ID) */
  valueLabel?: string;
  /** Logic operator to combine with NEXT condition (Motor Admin style) */
  nextLogic?: LogicOperator;
}

// ============================================================================
// Filter Group (for nested AND/OR logic)
// ============================================================================

export type LogicOperator = "and" | "or";

export interface FilterGroup {
  id: string;
  /** Logical operator for combining conditions */
  logic: LogicOperator;
  /** Conditions or nested groups */
  conditions: (FilterCondition | FilterGroup)[];
}

// ============================================================================
// Filter State
// ============================================================================

export interface FilterState {
  /** Root filter group */
  root: FilterGroup;
  /** Available fields for filtering */
  fields: FilterField[];
}

// ============================================================================
// Ransack Query Types
// ============================================================================

export type RansackConditionValue =
  | string
  | number
  | boolean
  | null
  | (string | number)[];

export interface RansackConditions {
  [predicateKey: string]: RansackConditionValue;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type RansackQuery = Record<string, any>;

// ============================================================================
// Component Props
// ============================================================================

export interface DynamicFilterProps {
  /** Resource being filtered (for URL updates) */
  resource: string;
  /** Available fields for filtering */
  fields: FilterField[];
  /** Initial filter state (from URL params) */
  initialFilters?: FilterGroup;
  /** Callback when filters are applied */
  onApply?: (query: RansackQuery) => void;
  /** Callback when filters are cleared */
  onClear?: () => void;
  /** Base URL for the filtered resource */
  baseUrl?: string;
  /** URL to redirect to with filter params (for drawer-based filter pages) */
  redirectUrl?: string;
  /** Enable advanced grouping (parentheses) */
  enableGrouping?: boolean;
  /** Enable saving filters */
  enableSavedFilters?: boolean;
  /** Account ID for multi-tenant */
  accountId?: number;
  /** Custom class name */
  className?: string;
}

export interface FilterItemProps {
  /** Filter condition */
  condition: FilterCondition;
  /** Available fields */
  fields: FilterField[];
  /** Update callback */
  onUpdate: (condition: FilterCondition) => void;
  /** Remove callback */
  onRemove: (id: string) => void;
  /** Account ID for dynamic lookups */
  accountId?: number;
}

export interface FilterGroupProps {
  /** Filter group */
  group: FilterGroup;
  /** Available fields */
  fields: FilterField[];
  /** Update callback */
  onUpdate: (group: FilterGroup) => void;
  /** Remove callback (for nested groups) */
  onRemove?: (id: string) => void;
  /** Nesting level */
  level?: number;
  /** Enable nested grouping */
  enableGrouping?: boolean;
  /** Account ID */
  accountId?: number;
}

// ============================================================================
// Saved Filter Types
// ============================================================================

export interface SavedFilter {
  id: string;
  name: string;
  resource?: string;
  filterGroup: FilterGroup;
  createdAt: string;
  updatedAt: string;
}

// ============================================================================
// Operator Configuration
// ============================================================================

import { tOperator } from "./i18n";

interface OperatorDef {
  key: OperatorKey;
  requiresValue: boolean;
  ransackSuffix: string;
}

const OPERATOR_DEFS: Record<OperatorKey, OperatorDef> = {
  eq: { key: "eq", requiresValue: true, ransackSuffix: "_eq" },
  not_eq: { key: "not_eq", requiresValue: true, ransackSuffix: "_not_eq" },
  cont: { key: "cont", requiresValue: true, ransackSuffix: "_cont" },
  not_cont: {
    key: "not_cont",
    requiresValue: true,
    ransackSuffix: "_not_cont",
  },
  start: { key: "start", requiresValue: true, ransackSuffix: "_start" },
  end: { key: "end", requiresValue: true, ransackSuffix: "_end" },
  matches: { key: "matches", requiresValue: true, ransackSuffix: "_matches" },
  gt: { key: "gt", requiresValue: true, ransackSuffix: "_gt" },
  gteq: { key: "gteq", requiresValue: true, ransackSuffix: "_gteq" },
  lt: { key: "lt", requiresValue: true, ransackSuffix: "_lt" },
  lteq: { key: "lteq", requiresValue: true, ransackSuffix: "_lteq" },
  null: { key: "null", requiresValue: false, ransackSuffix: "_null" },
  not_null: {
    key: "not_null",
    requiresValue: false,
    ransackSuffix: "_present",
  },
  present: { key: "present", requiresValue: false, ransackSuffix: "_present" },
  blank: { key: "blank", requiresValue: false, ransackSuffix: "_blank" },
  in: { key: "in", requiresValue: true, ransackSuffix: "_in" },
  not_in: { key: "not_in", requiresValue: true, ransackSuffix: "_not_in" },
};

export function getOperator(key: OperatorKey): Operator {
  const def = OPERATOR_DEFS[key];
  return { ...def, label: tOperator(key) };
}

export const OPERATORS: Record<OperatorKey, Operator> = new Proxy(
  {} as Record<OperatorKey, Operator>,
  {
    get(_target, prop: string) {
      if (prop in OPERATOR_DEFS) {
        return getOperator(prop as OperatorKey);
      }
      return undefined;
    },
    ownKeys() {
      return Object.keys(OPERATOR_DEFS);
    },
    getOwnPropertyDescriptor(_target, prop: string) {
      if (prop in OPERATOR_DEFS) {
        return {
          configurable: true,
          enumerable: true,
          writable: false,
          value: getOperator(prop as OperatorKey),
        };
      }
      return undefined;
    },
  },
);

// ============================================================================
// Operators by Field Type
// ============================================================================

export const OPERATORS_BY_TYPE: Record<FieldType, OperatorKey[]> = {
  string: ["eq", "not_eq", "cont", "start", "end", "null", "not_null"],
  text: ["eq", "not_eq", "cont", "start", "end", "null", "not_null"],
  number: ["eq", "not_eq", "gt", "gteq", "lt", "lteq", "null", "not_null"],
  integer: ["eq", "not_eq", "gt", "gteq", "lt", "lteq", "null", "not_null"],
  float: ["eq", "not_eq", "gt", "gteq", "lt", "lteq", "null", "not_null"],
  decimal: ["eq", "not_eq", "gt", "gteq", "lt", "lteq", "null", "not_null"],
  boolean: ["eq", "null", "not_null"],
  date: ["eq", "not_eq", "gt", "gteq", "lt", "lteq", "null", "not_null"],
  datetime: ["eq", "not_eq", "gt", "gteq", "lt", "lteq", "null", "not_null"],
  select: ["eq", "not_eq", "null", "not_null"],
  relation: ["eq", "not_eq", "null", "not_null"],
  reference: ["eq", "not_eq", "null", "not_null"],
};

// ============================================================================
// Helper Functions
// ============================================================================

export function getOperatorsForField(field: FilterField): Operator[] {
  const operatorKeys =
    OPERATORS_BY_TYPE[field.type] || OPERATORS_BY_TYPE.string;
  return operatorKeys.map((key) => getOperator(key));
}

export function isFilterGroup(
  item: FilterCondition | FilterGroup,
): item is FilterGroup {
  return "logic" in item && "conditions" in item;
}

export function isFilterCondition(
  item: FilterCondition | FilterGroup,
): item is FilterCondition {
  return "field" in item && "operator" in item;
}

export function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}

export function createEmptyCondition(
  nextLogic: LogicOperator = "and",
): FilterCondition {
  return {
    id: generateId(),
    field: "",
    operator: "eq",
    value: "",
    nextLogic,
  };
}

export function createEmptyGroup(logic: LogicOperator = "and"): FilterGroup {
  return {
    id: generateId(),
    logic,
    conditions: [createEmptyCondition()],
  };
}
