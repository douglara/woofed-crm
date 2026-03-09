/**
 * Ransack Query Builder
 *
 * Converts filter conditions/groups into Ransack-compatible query parameters.
 *
 * Ransack Query Format:
 * - Simple: { name_cont: 'john', status_eq: 'active' }
 * - OR: { name_cont: 'john', status_eq: 'active', m: 'or' }
 * - Grouped: { g: [{ name_cont: 'john', m: 'and' }, { status_eq: 'active', m: 'and' }], m: 'or' }
 * - Nested Associations: { user_email_cont: 'test@example.com' }
 *
 * Per-Condition Logic:
 * When conditions have nextLogic = 'or', we create groups at OR boundaries.
 * Example: A AND B OR C AND D => { g: [{ A, B, m: 'and' }, { C, D, m: 'and' }], m: 'or' }
 */

import {
  FilterCondition,
  FilterGroup,
  RansackQuery,
  OPERATORS,
  isFilterGroup,
  isFilterCondition,
} from "./types";

/**
 * Converts a FilterGroup to Ransack query parameters
 * Handles per-condition nextLogic for Motor Admin-style filters
 */
export function buildRansackQuery(group: FilterGroup): RansackQuery {
  // Handle empty group
  if (!group.conditions || group.conditions.length === 0) {
    return {};
  }

  // Filter out empty conditions
  const validConditions = group.conditions.filter((item) => {
    if (isFilterCondition(item)) {
      return item.field && item.operator;
    }
    if (isFilterGroup(item)) {
      return item.conditions.length > 0;
    }
    return false;
  });

  if (validConditions.length === 0) {
    return {};
  }

  // Check if we're using per-condition logic (nextLogic on conditions)
  const usePerConditionLogic = validConditions.some(
    (item) => isFilterCondition(item) && item.nextLogic,
  );

  if (usePerConditionLogic) {
    return buildQueryWithPerConditionLogic(
      validConditions as FilterCondition[],
    );
  }

  // Check if we have nested groups
  const hasNestedGroups = validConditions.some(isFilterGroup);

  if (hasNestedGroups) {
    return buildGroupedQuery(group);
  }

  // Simple flat query with group-level logic
  return buildFlatQueryWithGroupLogic(
    validConditions as FilterCondition[],
    group.logic,
  );
}

/**
 * Builds query using per-condition nextLogic (Motor Admin style)
 * Splits conditions into groups at OR boundaries
 */
function buildQueryWithPerConditionLogic(
  conditions: FilterCondition[],
): RansackQuery {
  if (conditions.length === 0) return {};

  // Check if there are any OR conditions
  const hasOrConditions = conditions.some(
    (c, i) => i < conditions.length - 1 && c.nextLogic === "or",
  );

  if (!hasOrConditions) {
    // All AND - flatten to simple query
    const query: RansackQuery = {};
    for (const condition of conditions) {
      const predicate = buildPredicate(condition);
      if (predicate) {
        Object.assign(query, predicate);
      }
    }
    return query;
  }

  // Group conditions by OR boundaries
  // A AND B OR C AND D => [[A, B], [C, D]]
  const groups: FilterCondition[][] = [];
  let currentGroup: FilterCondition[] = [];

  for (let i = 0; i < conditions.length; i++) {
    const condition = conditions[i];
    currentGroup.push(condition);

    // Check if this condition ends with OR (boundary)
    if (condition.nextLogic === "or" || i === conditions.length - 1) {
      groups.push([...currentGroup]);
      currentGroup = [];
    }
  }

  // Handle remaining conditions
  if (currentGroup.length > 0) {
    groups.push(currentGroup);
  }

  // If only one group, return flat query
  if (groups.length === 1) {
    const query: RansackQuery = {};
    for (const condition of groups[0]) {
      const predicate = buildPredicate(condition);
      if (predicate) {
        Object.assign(query, predicate);
      }
    }
    return query;
  }

  // Multiple groups: use Ransack's g parameter with m: 'or'
  const ransackGroups: RansackQuery[] = groups
    .map((group) => {
      const groupQuery: RansackQuery = {};
      for (const condition of group) {
        const predicate = buildPredicate(condition);
        if (predicate) {
          Object.assign(groupQuery, predicate);
        }
      }
      // Each group's conditions are AND'd together
      if (Object.keys(groupQuery).length > 1) {
        groupQuery.m = "and";
      }
      return groupQuery;
    })
    .filter((g) => Object.keys(g).length > 0);

  if (ransackGroups.length === 0) return {};
  if (ransackGroups.length === 1) return ransackGroups[0];

  return {
    g: ransackGroups,
    m: "or",
  };
}

/**
 * Builds a flat query with group-level logic
 */
function buildFlatQueryWithGroupLogic(
  conditions: FilterCondition[],
  logic: "and" | "or",
): RansackQuery {
  const query: RansackQuery = {};

  for (const condition of conditions) {
    const predicate = buildPredicate(condition);
    if (predicate) {
      Object.assign(query, predicate);
    }
  }

  // Add combinator if OR and more than 1 condition
  if (logic === "or" && Object.keys(query).length > 1) {
    query.m = "or";
  }

  return query;
}

/**
 * Builds a grouped query with Ransack's 'g' parameter
 * Used for complex AND/OR combinations
 */
function buildGroupedQuery(group: FilterGroup): RansackQuery {
  const groups: RansackQuery[] = [];

  for (const item of group.conditions) {
    if (isFilterCondition(item) && item.field && item.operator) {
      const predicate = buildPredicate(item);
      if (predicate) {
        groups.push(predicate);
      }
    } else if (isFilterGroup(item)) {
      const nestedQuery = buildRansackQuery(item);
      if (Object.keys(nestedQuery).length > 0) {
        groups.push(nestedQuery);
      }
    }
  }

  if (groups.length === 0) {
    return {};
  }

  if (groups.length === 1) {
    return groups[0];
  }

  return {
    g: groups,
    m: group.logic,
  };
}

/**
 * Builds a single predicate from a condition
 * Example: { field: 'name', operator: 'cont', value: 'john' } => { name_cont: 'john' }
 */
function buildPredicate(condition: FilterCondition): RansackQuery | null {
  const { field, operator, value } = condition;

  if (!field || !operator) {
    return null;
  }

  const op = OPERATORS[operator];
  if (!op) {
    return null;
  }

  // Handle operators that don't require a value
  if (!op.requiresValue) {
    // For null/not_null, blank/present, we need to pass 'true'
    const suffix = op.ransackSuffix;
    const ransackKey = buildRansackKey(field, suffix);
    return { [ransackKey]: true };
  }

  // Skip if value is empty for operators that require it
  if (value === null || value === undefined || value === "") {
    return null;
  }

  const suffix = op.ransackSuffix;
  const ransackKey = buildRansackKey(field, suffix);

  return { [ransackKey]: value };
}

/**
 * Builds the Ransack key from field name and suffix
 * Handles nested associations: 'user.email' => 'user_email'
 */
function buildRansackKey(field: string, suffix: string): string {
  // Replace dots with underscores for nested associations
  const normalizedField = field.replace(/\./g, "_");
  return `${normalizedField}${suffix}`;
}

/**
 * Parses bracket-notation URL params into a nested object.
 * e.g., filter[g][0][name_eq]=val → { g: { "0": { name_eq: "val" } } }
 */
function parseBracketParams(
  params: URLSearchParams,
  prefix: string,
): Record<string, unknown> {
  const result: Record<string, unknown> = {};

  params.forEach((value, key) => {
    if (!key.startsWith(prefix + "[")) return;

    // Extract bracket segments: "filter[g][0][name_eq]" → ["g", "0", "name_eq"]
    const bracketPart = key.slice(prefix.length);
    const parts: string[] = [];
    const regex = /\[([^\]]*)\]/g;
    let match;
    while ((match = regex.exec(bracketPart)) !== null) {
      parts.push(match[1]);
    }

    if (parts.length === 0) return;

    // Handle array push notation: filter[key][]
    if (parts.length >= 2 && parts[parts.length - 1] === "") {
      const arrayParts = parts.slice(0, -1);
      let current: Record<string, unknown> = result;
      for (let i = 0; i < arrayParts.length - 1; i++) {
        if (current[arrayParts[i]] === undefined) {
          current[arrayParts[i]] = {};
        }
        current = current[arrayParts[i]] as Record<string, unknown>;
      }
      const arrayKey = arrayParts[arrayParts.length - 1];
      if (!Array.isArray(current[arrayKey])) {
        current[arrayKey] = [];
      }
      (current[arrayKey] as unknown[]).push(value);
      return;
    }

    // Standard nested object notation
    let current: Record<string, unknown> = result;
    for (let i = 0; i < parts.length - 1; i++) {
      if (current[parts[i]] === undefined) {
        current[parts[i]] = {};
      }
      current = current[parts[i]] as Record<string, unknown>;
    }
    current[parts[parts.length - 1]] = value;
  });

  return result;
}

function generateParseId(): string {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Parses URL search params into a FilterGroup
 * This converts Ransack query params back into our filter structure
 */
export function parseRansackParams(params: URLSearchParams): FilterGroup {
  const query = parseBracketParams(params, "filter");
  return parseRansackQuery(query);
}

/**
 * Parses a Ransack query object into a FilterGroup
 * Supports both flat queries and grouped queries with `g` parameter
 */
export function parseRansackQuery(query: Record<string, unknown>): FilterGroup {
  const conditions: (FilterCondition | FilterGroup)[] = [];
  let logic: "and" | "or" = "and";
  let gValue: unknown = null;

  for (const [key, value] of Object.entries(query)) {
    if (key === "m") {
      logic = value === "or" ? "or" : "and";
      continue;
    }

    if (key === "g") {
      gValue = value;
      continue;
    }

    const condition = parsePredicate(key, value as string);
    if (condition) {
      conditions.push(condition);
    }
  }

  // Handle g groups
  if (gValue !== null && typeof gValue === "object") {
    const groupEntries = Array.isArray(gValue)
      ? gValue
      : Object.values(gValue as Record<string, unknown>);

    // Check if all sub-groups are simple flat queries (no nested g).
    // If so, flatten to per-condition logic format (Motor Admin style).
    const allFlat =
      conditions.length === 0 &&
      groupEntries.every(
        (g) =>
          typeof g === "object" &&
          g !== null &&
          !("g" in (g as Record<string, unknown>)),
      );

    if (allFlat) {
      for (let gi = 0; gi < groupEntries.length; gi++) {
        const groupData = groupEntries[gi] as Record<string, unknown>;
        const groupLogic = groupData.m === "or" ? "or" : "and";
        const groupConditions: FilterCondition[] = [];

        for (const [key, value] of Object.entries(groupData)) {
          if (key === "m") continue;
          const condition = parsePredicate(key, value as string);
          if (condition) {
            groupConditions.push(condition);
          }
        }

        // Set nextLogic for inter/intra-group connections
        for (let ci = 0; ci < groupConditions.length; ci++) {
          if (ci < groupConditions.length - 1) {
            // Within group: use the group's own logic
            groupConditions[ci].nextLogic = groupLogic;
          } else if (gi < groupEntries.length - 1) {
            // Last condition of a non-last group: use root logic (between groups)
            groupConditions[ci].nextLogic = logic;
          }
          // Last condition of last group: no nextLogic
        }

        conditions.push(...groupConditions);
      }

      // Root logic is "and" because OR boundaries are captured via nextLogic
      return {
        id: generateParseId(),
        logic: "and",
        conditions,
      };
    } else {
      // Complex nested groups: create FilterGroup hierarchy
      for (const groupData of groupEntries) {
        if (typeof groupData === "object" && groupData !== null) {
          const nestedGroup = parseRansackQuery(
            groupData as Record<string, unknown>,
          );
          if (nestedGroup.conditions.length > 0) {
            conditions.push(nestedGroup);
          }
        }
      }
    }
  }

  return {
    id: generateParseId(),
    logic,
    conditions,
  };
}

/**
 * Parses a single predicate into a FilterCondition
 * Example: 'name_cont' => { field: 'name', operator: 'cont' }
 */
function parsePredicate(key: string, value: unknown): FilterCondition | null {
  // Backward compat: handle old _not_null suffix from saved filters
  // Must check before main loop since _null would falsely match _not_null keys
  if (key.endsWith("_not_null")) {
    const field = key.slice(0, -"_not_null".length);
    return {
      id: `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      field: field,
      operator: "not_null",
      value: parseValue(value),
    };
  }

  // Sort operators by suffix length descending so longer suffixes match first
  // (e.g. _not_cont before _cont, _not_eq before _eq)
  const sortedOperators = Object.entries(OPERATORS).sort(
    ([, a], [, b]) => b.ransackSuffix.length - a.ransackSuffix.length,
  );

  for (const [opKey, op] of sortedOperators) {
    const suffix = op.ransackSuffix;
    if (key.endsWith(suffix)) {
      const field = key.slice(0, -suffix.length);
      return {
        id: `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        field: field,
        operator: opKey as FilterCondition["operator"],
        value: parseValue(value),
      };
    }
  }

  return null;
}

/**
 * Parses a value from URL params
 */
function parseValue(value: unknown): FilterCondition["value"] {
  if (value === null || value === undefined) {
    return null;
  }

  if (typeof value === "boolean") {
    return value;
  }

  if (typeof value === "number") {
    return value;
  }

  if (Array.isArray(value)) {
    return value as (string | number)[];
  }

  const strValue = String(value);

  // Try to parse as number
  if (/^-?\d+$/.test(strValue)) {
    return parseInt(strValue, 10);
  }

  if (/^-?\d+\.\d+$/.test(strValue)) {
    return parseFloat(strValue);
  }

  // Try to parse as boolean
  if (strValue === "true") return true;
  if (strValue === "false") return false;

  return strValue;
}

/**
 * Serializes a FilterGroup to URL search params
 */
export function serializeToUrlParams(group: FilterGroup): URLSearchParams {
  const query = buildRansackQuery(group);
  const params = new URLSearchParams();

  function addParams(obj: Record<string, unknown>, prefix: string = "filter") {
    for (const [key, value] of Object.entries(obj)) {
      if (value === null || value === undefined) continue;

      if (Array.isArray(value)) {
        // For arrays, use bracket notation
        value.forEach((v, i) => {
          if (typeof v === "object") {
            addParams(v as Record<string, unknown>, `${prefix}[${key}][${i}]`);
          } else {
            params.append(`${prefix}[${key}][]`, String(v));
          }
        });
      } else if (typeof value === "object") {
        addParams(value as Record<string, unknown>, `${prefix}[${key}]`);
      } else {
        params.append(`${prefix}[${key}]`, String(value));
      }
    }
  }

  addParams(query);
  return params;
}

/**
 * Builds a simple query string from filters
 */
export function buildQueryString(group: FilterGroup): string {
  const params = serializeToUrlParams(group);
  return params.toString();
}
