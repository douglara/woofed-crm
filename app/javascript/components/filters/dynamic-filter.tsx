/**
 * DynamicFilter Component
 *
 * Main filter component that provides a Motor Admin-like filtering experience.
 * Generates Ransack-compatible query parameters.
 *
 * Features:
 * - Multiple conditions with AND/OR logic
 * - Dynamic field types with appropriate inputs
 * - Nested grouping support
 * - URL serialization
 * - Saved filters support
 */

import * as React from "react";
import { PlusIcon, FilterIcon, XIcon, SaveIcon } from "lucide-react";
import { cn } from "@/lib/utils";
import { FilterItem } from "./filter-item";
import { useFilterState } from "./use-filter-state";
import { tFilter } from "./i18n";
import {
  FilterField,
  FilterGroup,
  FilterCondition,
  LogicOperator,
  isFilterCondition,
  isFilterGroup,
  DynamicFilterProps,
} from "./types";

export function DynamicFilter({
  resource: _resource,
  fields,
  initialFilters,
  onApply,
  onClear,
  baseUrl,
  redirectUrl,
  enableGrouping = false,
  enableSavedFilters = false,
  accountId,
  className,
}: DynamicFilterProps) {
  const {
    filterGroup,
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
  } = useFilterState({
    initialFilters,
    fields,
    baseUrl,
    redirectUrl,
  });

  // Handle apply
  const handleApply = React.useCallback(() => {
    const query = buildQuery();
    onApply?.(query);
    applyFilters();
  }, [buildQuery, onApply, applyFilters]);

  // Handle clear
  const handleClear = React.useCallback(() => {
    onClear?.();
    clearFilters();
  }, [onClear, clearFilters]);

  // Handle condition update
  const handleUpdateCondition = React.useCallback(
    (conditionId: string, condition: FilterCondition) => {
      updateCondition(conditionId, condition);
    },
    [updateCondition],
  );

  return (
    <div className={cn("space-y-4", className)}>
      {/* Header */}
      <div className="flex items-center justify-between hidden">
        <div className="flex items-center gap-2">
          <FilterIcon className="size-4 text-muted-foreground" />
          <span className="text-sm font-medium">
            {tFilter("filters")}
            {filterCount > 0 && (
              <span className="ml-1 text-muted-foreground">
                ({filterCount})
              </span>
            )}
          </span>
        </div>
        {enableSavedFilters && (
          <button type="button" className="button-default-blank-secondary-sm">
            <SaveIcon className="size-4" />
            {tFilter("save")}
          </button>
        )}
      </div>

      {/* Filter Groups */}
      <FilterGroupComponent
        group={filterGroup}
        fields={fields}
        onUpdateCondition={handleUpdateCondition}
        onRemoveCondition={removeCondition}
        onAddCondition={addCondition}
        onToggleLogic={toggleLogic}
        onSetLogic={setLogic}
        onAddGroup={addGroup}
        onRemoveGroup={removeGroup}
        enableGrouping={enableGrouping}
        accountId={accountId}
        isRoot
      />

      {/* Actions */}
      <div className="flex items-center justify-between gap-2 pt-2">
        <button
          type="button"
          className="button-default-blank-secondary-sm disabled:opacity-50 disabled:pointer-events-none"
          onClick={handleClear}
          disabled={!hasFilters}
        >
          {tFilter("clear_all")}
        </button>
        <button
          type="button"
          className="button-default-fill-primary-sm"
          onClick={handleApply}
        >
          {tFilter("apply_filters")}
        </button>
      </div>
    </div>
  );
}

// ============================================================================
// Filter Group Component
// ============================================================================

interface FilterGroupComponentProps {
  group: FilterGroup;
  fields: FilterField[];
  onUpdateCondition: (conditionId: string, condition: FilterCondition) => void;
  onRemoveCondition: (conditionId: string) => void;
  onAddCondition: (groupId?: string) => void;
  onToggleLogic: (groupId?: string) => void;
  onSetLogic: (groupId: string, logic: LogicOperator) => void;
  onAddGroup: (parentGroupId?: string, logic?: LogicOperator) => void;
  onRemoveGroup: (groupId: string) => void;
  enableGrouping?: boolean;
  accountId?: number;
  isRoot?: boolean;
  level?: number;
}

function FilterGroupComponent({
  group,
  fields,
  onUpdateCondition,
  onRemoveCondition,
  onAddCondition,
  onToggleLogic: _onToggleLogic,
  onSetLogic: _onSetLogic,
  onAddGroup,
  onRemoveGroup,
  enableGrouping = false,
  accountId,
  isRoot = false,
  level = 0,
}: FilterGroupComponentProps) {
  const conditions = group.conditions;
  const conditionCount = conditions.filter(isFilterCondition).length;

  // Handle toggling logic between conditions (Motor Admin style)
  const handleToggleConditionLogic = React.useCallback(
    (conditionId: string, newLogic: "and" | "or") => {
      const condition = conditions.find(
        (c) => isFilterCondition(c) && c.id === conditionId,
      );
      if (condition && isFilterCondition(condition)) {
        onUpdateCondition(conditionId, {
          ...condition,
          nextLogic: newLogic,
        });
      }
    },
    [conditions, onUpdateCondition],
  );

  return (
    <div
      className={cn(
        "flex flex-col gap-2",
        !isRoot && "pl-4 border-l-2 border-border",
      )}
    >
      {conditions.map((item, index) => {
        const isLastCondition = index === conditions.length - 1;

        // Render condition
        if (isFilterCondition(item)) {
          return (
            <div key={item.id} className="relative">
              <FilterItem
                condition={item}
                fields={fields}
                onUpdate={(condition) => onUpdateCondition(item.id, condition)}
                onRemove={onRemoveCondition}
                accountId={accountId}
                showRemove={conditionCount > 1 || !isRoot}
              />

              {/* Logic toggle between conditions - Motor Admin style */}
              {!isLastCondition && (
                <div className="flex justify-center py-1">
                  <ConditionLogicToggle
                    logic={item.nextLogic || "and"}
                    onToggle={(newLogic) =>
                      handleToggleConditionLogic(item.id, newLogic)
                    }
                  />
                </div>
              )}
            </div>
          );
        }

        // Render nested group
        if (isFilterGroup(item)) {
          return (
            <div key={item.id} className="relative">
              <FilterGroupComponent
                group={item}
                fields={fields}
                onUpdateCondition={onUpdateCondition}
                onRemoveCondition={onRemoveCondition}
                onAddCondition={onAddCondition}
                onToggleLogic={_onToggleLogic}
                onSetLogic={_onSetLogic}
                onAddGroup={onAddGroup}
                onRemoveGroup={onRemoveGroup}
                enableGrouping={enableGrouping}
                accountId={accountId}
                level={level + 1}
              />
              <button
                type="button"
                className="absolute -right-1 -top-1 button-default-blank-secondary-icon-only-sm hover:text-auxiliary-palette-red"
                onClick={() => onRemoveGroup(item.id)}
              >
                <XIcon className="size-3" />
              </button>
            </div>
          );
        }

        return null;
      })}

      {/* Add condition/group buttons */}
      <div className="flex items-center gap-2 pt-2">
        <button
          type="button"
          className="button-default-blank-secondary-sm"
          onClick={() => onAddCondition(group.id)}
        >
          <PlusIcon className="size-4" />
          {tFilter("add_condition")}
        </button>
        {enableGrouping && level < 2 && (
          <button
            type="button"
            className="button-default-blank-secondary-sm"
            onClick={() => onAddGroup(group.id, "and")}
          >
            <PlusIcon className="size-4" />
            {tFilter("add_group")}
          </button>
        )}
      </div>
    </div>
  );
}

// ============================================================================
// Condition Logic Toggle (Motor Admin style - between conditions)
// ============================================================================

interface ConditionLogicToggleProps {
  logic: "and" | "or";
  onToggle: (newLogic: "and" | "or") => void;
}

function ConditionLogicToggle({ logic, onToggle }: ConditionLogicToggleProps) {
  return (
    <button
      type="button"
      onClick={() => onToggle(logic === "and" ? "or" : "and")}
      className={cn(
        "px-3 py-1 text-xs font-semibold rounded uppercase cursor-pointer transition-colors border shadow-sm",
        logic === "and"
          ? "bg-brand-palette-08 text-brand-palette-03 border-brand-palette-05 hover:bg-brand-palette-07"
          : "bg-auxiliary-palette-red-down-2 text-auxiliary-palette-red border-auxiliary-palette-red-down hover:bg-auxiliary-palette-red-down",
      )}
    >
      {logic === "and" ? tFilter("logic_and") : tFilter("logic_or")}
    </button>
  );
}

export default DynamicFilter;
