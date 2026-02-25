import { Controller } from "@hotwired/stimulus";
import { Dropdown } from "flowbite";

export default class extends Controller {
  static targets = [
    "filterContainer",
    "filterTemplate",
    "form",
    "button",
    "activeFiltersCount"
  ];

  static values = {
    models: Array,
    fieldsByModel: Object,
    operators: Object,
    users: Array,
    filterCount: { type: Number, default: 0 }
  };

  connect() {
    this.initializeFromUrl();
    this.updateActiveFiltersDisplay();
  }

  initializeFromUrl() {
    const params = new URLSearchParams(window.location.search);
    const qParams = {};

    params.forEach((value, key) => {
      if (key.startsWith('q[')) {
        const match = key.match(/q\[([^\]]+)\](\[\])?/);
        if (match) {
          const fieldKey = match[1];
          const isArray = match[2] === '[]';
          if (isArray) {
            if (!qParams[fieldKey]) qParams[fieldKey] = [];
            qParams[fieldKey].push(value);
          } else {
            qParams[fieldKey] = value;
          }
        }
      }
    });

    Object.entries(qParams).forEach(([key, value]) => {
      this.addFilterFromParam(key, value);
    });
  }

  addFilterFromParam(paramKey, value) {
    const operatorPatterns = ['_not_cont', '_not_eq', '_not_in', '_gteq', '_lteq', '_cont', '_eq', '_in', '_present', '_blank'];
    let fullFieldKey = paramKey;
    let operator = '_cont';

    for (const op of operatorPatterns) {
      if (paramKey.endsWith(op)) {
        fullFieldKey = paramKey.slice(0, -op.length);
        operator = op;
        break;
      }
    }

    // Determine which model this field belongs to
    const { modelKey, fieldKey } = this.parseFieldKey(fullFieldKey);

    this.addFilter(null, modelKey, fieldKey, operator, value);
  }

  parseFieldKey(fullFieldKey) {
    // Check prefixes to determine model
    for (const model of this.modelsValue) {
      if (model.prefix && fullFieldKey.startsWith(model.prefix)) {
        return {
          modelKey: model.key,
          fieldKey: fullFieldKey
        };
      }
    }
    // Default to deal model
    return {
      modelKey: 'deal',
      fieldKey: fullFieldKey
    };
  }

  addFilter(event, presetModel = null, presetField = null, presetOperator = null, presetValue = null) {
    event?.preventDefault();

    const template = this.filterTemplateTarget.content.cloneNode(true);
    const filterRow = template.querySelector('.filter-row');

    this.filterCountValue++;
    filterRow.dataset.filterIndex = this.filterCountValue;

    this.filterContainerTarget.appendChild(filterRow);
    this.initializeFilterRow(filterRow, presetModel, presetField, presetOperator, presetValue);
    this.updateActiveFiltersDisplay();

    if (typeof lucide !== 'undefined') {
      lucide.createIcons();
    }
  }

  initializeFilterRow(filterRow, presetModel = null, presetField = null, presetOperator = null, presetValue = null) {
    const modelSelect = filterRow.querySelector('[data-role="modelSelect"]');
    const fieldSelect = filterRow.querySelector('[data-role="fieldSelect"]');

    // Populate model select
    this.populateModelSelect(modelSelect);

    if (presetModel) {
      modelSelect.value = presetModel;
      this.updateFieldsForRow(filterRow, presetModel);

      if (presetField && fieldSelect) {
        fieldSelect.value = presetField;
        this.updateOperatorsForRow(filterRow, presetField);

        const operatorSelect = filterRow.querySelector('[data-role="operatorSelect"]');
        if (presetOperator && operatorSelect) {
          operatorSelect.value = presetOperator;
        }

        this.updateValueInput(filterRow, presetField, presetOperator || '_cont', presetValue);
      }
    }
  }

  populateModelSelect(modelSelect) {
    if (!modelSelect) return;

    modelSelect.innerHTML = `<option value="">${this.selectModelText()}</option>` +
      this.modelsValue.map(model =>
        `<option value="${model.key}">${model.label}</option>`
      ).join('');
  }

  selectModelText() {
    return 'Select model...';
  }

  modelChanged(event) {
    const filterRow = event.target.closest('.filter-row');
    const selectedModel = event.target.value;

    this.updateFieldsForRow(filterRow, selectedModel);
    this.clearOperatorAndValue(filterRow);
  }

  updateFieldsForRow(filterRow, modelKey) {
    const fieldSelect = filterRow.querySelector('[data-role="fieldSelect"]');
    if (!fieldSelect) return;

    const fields = this.fieldsByModelValue[modelKey] || [];

    fieldSelect.innerHTML = `<option value="">Select field...</option>` +
      fields.map(field =>
        `<option value="${field.key}" data-type="${field.type}">${field.label}</option>`
      ).join('');

    fieldSelect.disabled = fields.length === 0;
  }

  fieldChanged(event) {
    const filterRow = event.target.closest('.filter-row');
    const selectedField = event.target.value;

    this.updateOperatorsForRow(filterRow, selectedField);
    this.updateValueInput(filterRow, selectedField);
  }

  updateOperatorsForRow(filterRow, fieldKey) {
    const operatorSelect = filterRow.querySelector('[data-role="operatorSelect"]');
    if (!operatorSelect) return;

    const fieldType = this.getFieldType(filterRow, fieldKey);
    const operators = this.operatorsValue[fieldType] || this.operatorsValue['text'];

    operatorSelect.innerHTML = operators.map(op =>
      `<option value="${op.value}">${op.label}</option>`
    ).join('');

    operatorSelect.disabled = false;
  }

  getFieldType(filterRow, fieldKey) {
    const modelSelect = filterRow.querySelector('[data-role="modelSelect"]');
    const modelKey = modelSelect?.value;
    const fields = this.fieldsByModelValue[modelKey] || [];
    const field = fields.find(f => f.key === fieldKey);
    return field?.type || 'text';
  }

  getFieldConfig(filterRow, fieldKey) {
    const modelSelect = filterRow.querySelector('[data-role="modelSelect"]');
    const modelKey = modelSelect?.value;
    const fields = this.fieldsByModelValue[modelKey] || [];
    return fields.find(f => f.key === fieldKey);
  }

  operatorChanged(event) {
    const filterRow = event.target.closest('.filter-row');
    const fieldSelect = filterRow.querySelector('[data-role="fieldSelect"]');
    const selectedField = fieldSelect?.value;
    const selectedOperator = event.target.value;

    this.updateValueInput(filterRow, selectedField, selectedOperator);
  }

  clearOperatorAndValue(filterRow) {
    const operatorSelect = filterRow.querySelector('[data-role="operatorSelect"]');
    const valueContainer = filterRow.querySelector('[data-role="valueContainer"]');

    if (operatorSelect) {
      operatorSelect.innerHTML = '<option value="">Select operator...</option>';
      operatorSelect.disabled = true;
    }

    if (valueContainer) {
      valueContainer.innerHTML = '<input type="text" class="form-input flex-1 text-sm" placeholder="Select field first..." disabled>';
    }
  }

  updateValueInput(filterRow, fieldKey, operator = '_cont', presetValue = null) {
    const valueContainer = filterRow.querySelector('[data-role="valueContainer"]');
    if (!valueContainer) return;

    const field = this.getFieldConfig(filterRow, fieldKey);

    if (operator === '_present' || operator === '_blank') {
      valueContainer.innerHTML = `
        <input type="hidden" name="q[${fieldKey}${operator}]" value="true" data-role="valueInput">
        <span class="typography-text-m-lh150 color-fg-soft italic px-2">(no value needed)</span>
      `;
      return;
    }

    switch (field?.type) {
      case 'select':
        valueContainer.innerHTML = this.buildSelectInput(field, operator, presetValue);
        break;
      case 'date':
      case 'datetime':
        valueContainer.innerHTML = this.buildDateInput(field, operator, presetValue);
        break;
      case 'multi_select':
        valueContainer.innerHTML = this.buildMultiSelectInput(field, operator, presetValue);
        break;
      case 'number':
        valueContainer.innerHTML = this.buildNumberInput(field, operator, presetValue);
        break;
      case 'boolean':
        valueContainer.innerHTML = this.buildBooleanInput(field, operator, presetValue);
        break;
      default:
        valueContainer.innerHTML = this.buildTextInput(field, fieldKey, operator, presetValue);
    }
  }

  buildTextInput(field, fieldKey, operator, presetValue) {
    const key = field?.key || fieldKey || '';
    const name = `q[${key}${operator}]`;
    const value = presetValue ? `value="${this.escapeHtml(presetValue)}"` : '';
    return `<input type="text" name="${name}" ${value}
            class="form-input flex-1 text-sm" placeholder="Enter value..."
            data-role="valueInput">`;
  }

  buildSelectInput(field, operator, presetValue) {
    const name = `q[${field.key}${operator}]`;
    const options = field.options?.map(opt =>
      `<option value="${opt.value}" ${presetValue === opt.value ? 'selected' : ''}>${opt.label}</option>`
    ).join('') || '';
    return `<select name="${name}" class="form-input flex-1 text-sm" data-role="valueInput">
            <option value="">Select...</option>${options}</select>`;
  }

  buildDateInput(field, operator, presetValue) {
    const name = `q[${field.key}${operator}]`;
    const value = presetValue ? `value="${presetValue}"` : '';
    const inputType = field.type === 'datetime' ? 'datetime-local' : 'date';
    return `<input type="${inputType}" name="${name}" ${value} class="form-input flex-1 text-sm" data-role="valueInput">`;
  }

  buildMultiSelectInput(field, operator, presetValue) {
    const name = `q[${field.key}${operator}][]`;
    const selectedValues = Array.isArray(presetValue) ? presetValue : (presetValue ? [presetValue] : []);

    const checkboxes = this.usersValue.map(user => `
      <label class="flex items-center gap-2 py-1 px-2 hover:bg-light-palette-p4 rounded cursor-pointer">
        <input type="checkbox" name="${name}" value="${user.id}"
               ${selectedValues.includes(String(user.id)) ? 'checked' : ''}
               class="form-checkbox rounded text-brand-palette-03 focus:ring-brand-palette-03">
        <span class="typography-text-m-lh150">${this.escapeHtml(user.name)}</span>
      </label>
    `).join('');

    return `<div class="max-h-40 overflow-y-auto border border-light-palette-p3 rounded-md bg-white">${checkboxes}</div>`;
  }

  buildNumberInput(field, operator, presetValue) {
    const name = `q[${field.key}${operator}]`;
    const value = presetValue ? `value="${presetValue}"` : '';
    return `<input type="number" name="${name}" ${value}
            class="form-input flex-1 text-sm" placeholder="Enter value..."
            data-role="valueInput">`;
  }

  buildBooleanInput(field, operator, presetValue) {
    const name = `q[${field.key}${operator}]`;
    return `<select name="${name}" class="form-input flex-1 text-sm" data-role="valueInput">
            <option value="">Select...</option>
            <option value="true" ${presetValue === 'true' ? 'selected' : ''}>Yes</option>
            <option value="false" ${presetValue === 'false' ? 'selected' : ''}>No</option>
            </select>`;
  }

  removeFilter(event) {
    event.preventDefault();
    const filterRow = event.target.closest('.filter-row');
    filterRow.remove();
    this.updateActiveFiltersDisplay();
  }

  applyFilters(event) {
    event.preventDefault();

    const formData = new FormData(this.formTarget);
    const params = new URLSearchParams();

    const currentParams = new URLSearchParams(window.location.search);
    const statusFilter = currentParams.get('filter_status_deal');
    if (statusFilter) {
      params.set('filter_status_deal', statusFilter);
    }

    for (const [key, value] of formData.entries()) {
      if (value && value.trim() !== '' && key !== 'filter_status_deal') {
        params.append(key, value);
      }
    }

    window.history.pushState({}, '', `?${params.toString()}`);
    this.formTarget.requestSubmit();
    this.hideDropdown();
  }

  clearFilters(event) {
    event.preventDefault();
    this.filterContainerTarget.innerHTML = '';

    const currentParams = new URLSearchParams(window.location.search);
    const statusFilter = currentParams.get('filter_status_deal');
    const newParams = new URLSearchParams();
    if (statusFilter) {
      newParams.set('filter_status_deal', statusFilter);
    }

    window.history.pushState({}, '', newParams.toString() ? `?${newParams.toString()}` : window.location.pathname);
    this.formTarget.requestSubmit();
    this.updateActiveFiltersDisplay();
    this.hideDropdown();
  }

  updateActiveFiltersDisplay() {
    const count = this.filterContainerTarget.querySelectorAll('.filter-row').length;
    if (this.hasActiveFiltersCountTarget) {
      this.activeFiltersCountTarget.textContent = count;
      this.activeFiltersCountTarget.classList.toggle('hidden', count === 0);
    }
    if (this.hasButtonTarget) {
      this.buttonTarget.ariaSelected = count > 0 ? "true" : "false";
    }
  }

  hideDropdown() {
    const dropdownEl = document.getElementById('advancedFilterDropdown');
    if (dropdownEl && this.hasButtonTarget) {
      const dropdown = new Dropdown(dropdownEl, this.buttonTarget);
      dropdown.hide();
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}
