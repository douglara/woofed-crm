/**
 * FilterItem Component
 *
 * Renders a single filter condition with:
 * - Field selector (Combobox)
 * - Operator selector (Select - fixed, non-searchable)
 * - Value input (dynamic based on field type)
 * - Remove button
 */

import * as React from "react";
import { XIcon } from "lucide-react";
import { Input } from "@/components/ui/input";
import {
  Combobox,
  ComboboxInput,
  ComboboxContent,
  ComboboxList,
  ComboboxItem,
} from "@/components/ui/combobox";
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select";
import { DynamicCombobox } from "@/components/ui/dynamic-combobox";
import {
  FilterCondition,
  FilterField,
  Operator,
  OperatorKey,
  getOperatorsForField,
  OPERATORS,
} from "./types";
import { tFilter } from "./i18n";

export interface FilterItemProps {
  condition: FilterCondition;
  fields: FilterField[];
  onUpdate: (condition: FilterCondition) => void;
  onRemove: (id: string) => void;
  accountId?: number;
  showRemove?: boolean;
}

export function FilterItem({
  condition,
  fields,
  onUpdate,
  onRemove,
  accountId,
  showRemove = true,
}: FilterItemProps) {
  // Get selected field
  const selectedField = React.useMemo(
    () => fields.find((f) => f.name === condition.field),
    [fields, condition.field],
  );

  // Get available operators for selected field
  const operators = React.useMemo(
    () =>
      selectedField
        ? getOperatorsForField(selectedField)
        : Object.values(OPERATORS).slice(0, 6),
    [selectedField],
  );

  // Get selected operator
  const selectedOperator = React.useMemo(
    () => OPERATORS[condition.operator],
    [condition.operator],
  );

  // Handle field change
  const handleFieldChange = React.useCallback(
    (value: string | null) => {
      if (value) {
        const newField = fields.find((f) => f.name === value);
        const newOperators = newField ? getOperatorsForField(newField) : [];

        // Reset operator if not valid for new field
        let newOperator = condition.operator;
        if (!newOperators.find((op) => op.key === condition.operator)) {
          newOperator = newOperators[0]?.key || "eq";
        }

        onUpdate({
          ...condition,
          field: value,
          operator: newOperator,
          value: "", // Reset value on field change
          valueLabel: undefined, // Reset label on field change
        });
      }
    },
    [condition, fields, onUpdate],
  );

  // Handle operator change
  const handleOperatorChange = React.useCallback(
    (value: string | null) => {
      if (!value) return;
      const op = OPERATORS[value as OperatorKey];
      onUpdate({
        ...condition,
        operator: value as OperatorKey,
        // Clear value and valueLabel if new operator doesn't require it
        value: op?.requiresValue ? condition.value : "",
        valueLabel: op?.requiresValue ? condition.valueLabel : undefined,
      });
    },
    [condition, onUpdate],
  );

  // Handle value change
  const handleValueChange = React.useCallback(
    (value: string | number | boolean | null, label?: string) => {
      onUpdate({
        ...condition,
        value: value ?? "",
        valueLabel: label,
      });
    },
    [condition, onUpdate],
  );

  return (
    <div className="relative pb-2">
      <div className="flex items-stretch gap-2">
        {/* Field Selector */}
        <div className="flex-1 min-w-0">
          <FieldSelectorCombobox
            value={condition.field}
            fields={fields}
            onChange={handleFieldChange}
          />
        </div>

        {/* Operator Selector (fixed Select, not searchable) */}
        <div className="w-32 shrink-0">
          <Select
            value={condition.operator}
            onValueChange={handleOperatorChange}
          >
            <SelectTrigger className="w-full h-9">
              <SelectValue placeholder={tFilter("select_operator")} />
            </SelectTrigger>
            <SelectContent>
              {operators.map((op) => (
                <SelectItem key={op.key} value={op.key}>
                  {op.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {/* Value Input - key forces remount when field changes */}
        <div className="flex-1 min-w-0">
          <FilterValueInput
            key={`${condition.field}-${condition.operator}`}
            field={selectedField}
            operator={selectedOperator}
            value={condition.value}
            valueLabel={condition.valueLabel}
            onChange={handleValueChange}
            accountId={accountId}
          />
        </div>

        {/* Remove Button */}
        {showRemove && (
          <button
            type="button"
            className="button-default-blank-secondary-icon-only-sm shrink-0 hover:text-auxiliary-palette-red"
            onClick={() => onRemove(condition.id)}
          >
            <XIcon className="size-4" />
          </button>
        )}
      </div>
    </div>
  );
}

// ============================================================================
// Field Selector Combobox (with local text filtering)
// ============================================================================

interface FieldSelectorComboboxProps {
  value: string;
  fields: FilterField[];
  onChange: (value: string | null) => void;
}

function FieldSelectorCombobox({
  value,
  fields,
  onChange,
}: FieldSelectorComboboxProps) {
  const [inputValue, setInputValue] = React.useState("");

  // Find label for selected value
  const selectedLabel = React.useMemo(() => {
    const field = fields.find((f) => f.name === value);
    return field?.label ?? "";
  }, [fields, value]);

  // Filter fields locally by input text
  const filteredFields = React.useMemo(() => {
    if (!inputValue) return fields;
    const search = inputValue.toLowerCase();
    return fields.filter((f) => f.label.toLowerCase().includes(search));
  }, [fields, inputValue]);

  const handleValueChange = (newValue: string | null) => {
    setInputValue(""); // Clear search text after selection
    onChange(newValue);
  };

  // Display: if user is typing show their input, otherwise show selected label
  const displayValue = inputValue || selectedLabel;

  return (
    <Combobox
      value={value}
      onValueChange={handleValueChange}
      filter={null} // We handle filtering ourselves
    >
      <ComboboxInput
        placeholder={tFilter("select_field")}
        className="w-full"
        value={displayValue}
        onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
          setInputValue(e.target.value)
        }
        onFocus={() => setInputValue("")}
        onBlur={() => setInputValue("")}
      />
      <ComboboxContent>
        <ComboboxList>
          {filteredFields.length === 0 ? (
            <div className="py-2 text-center text-sm text-muted-foreground">
              {tFilter("no_fields_found")}
            </div>
          ) : (
            filteredFields.map((field) => (
              <ComboboxItem key={field.name} value={field.name}>
                {field.label}
              </ComboboxItem>
            ))
          )}
        </ComboboxList>
      </ComboboxContent>
    </Combobox>
  );
}

// ============================================================================
// Value Input Component
// ============================================================================

interface FilterValueInputProps {
  field?: FilterField;
  operator?: Operator;
  value: FilterCondition["value"];
  valueLabel?: string;
  onChange: (value: string | number | boolean | null, label?: string) => void;
  accountId?: number;
}

function FilterValueInput({
  field,
  operator,
  value,
  valueLabel,
  onChange,
  accountId,
}: FilterValueInputProps) {
  // If operator doesn't require value, show disabled input
  if (operator && !operator.requiresValue) {
    return <Input disabled placeholder="—" className="text-muted-foreground" />;
  }

  // If no field selected, show basic text input
  if (!field) {
    return (
      <Input
        type="text"
        placeholder={tFilter("enter_value")}
        value={String(value ?? "")}
        onChange={(e) => onChange(e.target.value)}
      />
    );
  }

  // Render based on field type
  switch (field.type) {
    case "boolean":
      return (
        <Combobox
          value={value === true ? "true" : value === false ? "false" : ""}
          onValueChange={(v) =>
            onChange(v === "true" ? true : v === "false" ? false : null)
          }
        >
          <ComboboxInput placeholder={tFilter("select")} className="w-full" />
          <ComboboxContent>
            <ComboboxList>
              <ComboboxItem value="true">{tFilter("yes")}</ComboboxItem>
              <ComboboxItem value="false">{tFilter("no")}</ComboboxItem>
            </ComboboxList>
          </ComboboxContent>
        </Combobox>
      );

    case "select":
      return (
        <Combobox
          value={String(value ?? "")}
          onValueChange={(v) => onChange(v)}
        >
          <ComboboxInput placeholder={tFilter("select")} className="w-full" />
          <ComboboxContent>
            <ComboboxList>
              {(field.options || []).map((opt) => (
                <ComboboxItem key={String(opt.value)} value={String(opt.value)}>
                  {opt.label}
                </ComboboxItem>
              ))}
            </ComboboxList>
          </ComboboxContent>
        </Combobox>
      );

    // Relation type: uses DynamicCombobox for FK lookups
    case "relation":
      return (
        <RelationValueInput
          field={field}
          value={value}
          valueLabel={valueLabel}
          onChange={onChange}
          accountId={accountId}
        />
      );

    case "reference":
      if (field.reference?.model && accountId) {
        return (
          <DynamicCombobox
            value={value as number | null}
            onChange={(v) => onChange(v)}
            modelName={field.reference.model.toLowerCase()}
            ransackParam={`${field.reference.displayKey}_cont`}
            accountId={accountId}
            placeholder={tFilter("search")}
          />
        );
      }
      return (
        <Input
          type="text"
          placeholder={tFilter("enter_id")}
          value={String(value ?? "")}
          onChange={(e) => onChange(e.target.value)}
        />
      );

    case "integer":
    case "float":
    case "decimal":
    case "number":
      return (
        <Input
          type="number"
          placeholder={tFilter("enter_number")}
          value={String(value ?? "")}
          onChange={(e) => {
            const num = parseFloat(e.target.value);
            onChange(isNaN(num) ? e.target.value : num);
          }}
          step={field.type === "integer" ? "1" : "any"}
        />
      );

    case "date": {
      const toLocalDatetime = (value) => {
        if (!value) return "";

        const date = new Date(value);
        const pad = (n) => String(n).padStart(2, "0");

        return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
      };

      return (
        <Input
          type="datetime-local"
          value={toLocalDatetime(value)}
          onChange={(e) => {
            const localValue = e.target.value;
            const utcValue = new Date(localValue).toISOString();
            onChange(utcValue);
          }}
        />
      );
    }

    case "datetime": {
      const toLocalDatetime = (value) => {
        if (!value) return "";

        const date = new Date(value);
        const pad = (n) => String(n).padStart(2, "0");

        return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
      };

      return (
        <Input
          type="datetime-local"
          value={toLocalDatetime(value)}
          onChange={(e) => {
            const localValue = e.target.value;
            const utcValue = new Date(localValue).toISOString();
            onChange(utcValue);
          }}
        />
      );
    }

    case "string":
    case "text":
    default:
      return (
        <Input
          type="text"
          placeholder={tFilter("enter_value")}
          value={String(value ?? "")}
          onChange={(e) => onChange(e.target.value)}
        />
      );
  }
}

// ============================================================================
// Relation Value Input (for FK fields with dynamic search)
// ============================================================================

interface RelationValueInputProps {
  field: FilterField;
  value: FilterCondition["value"];
  valueLabel?: string;
  onChange: (value: string | number | boolean | null, label?: string) => void;
  accountId?: number;
}

function RelationValueInput({
  field,
  value,
  valueLabel: _valueLabel,
  onChange,
  accountId,
}: RelationValueInputProps) {
  const relation = field.relation;

  // Use combobox controller search when modelName is available
  if (relation?.modelName && accountId) {
    return (
      <DynamicCombobox
        value={value as number | string | null}
        onChange={(v, selectedItem) => {
          const label = selectedItem?.label ?? undefined;
          onChange(v, label);
        }}
        modelName={relation.modelName}
        ransackParam={relation.searchKey || `${relation.labelKey}_cont`}
        accountId={accountId}
        placeholder={tFilter("search")}
        fetchOnOpen={true}
      />
    );
  }

  // Fallback: just show text input for ID (no endpoint configured)
  return (
    <Input
      type="text"
      placeholder={tFilter("enter_id")}
      value={String(value ?? "")}
      onChange={(e) => onChange(e.target.value)}
    />
  );
}

export default FilterItem;
