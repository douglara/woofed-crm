import { Controller } from "@hotwired/stimulus";
import { createElement } from "react";
import { createRoot } from "react-dom/client";
import { DynamicFilter } from "@/components/filters";
import { parseRansackQuery } from "@/components/filters/ransack-builder";

export default class extends Controller {
  static values = {
    resource: { type: String, default: "deals" },
    fields: { type: Array, default: [] },
    accountId: Number,
    baseUrl: { type: String, default: "" },
    redirectUrl: { type: String, default: "" },
    enableGrouping: { type: Boolean, default: false },
    initialFilters: { type: Object, default: {} },
  };

  connect() {
    this.root = createRoot(this.element);
    this._render();
  }

  disconnect() {
    this.root?.unmount();
  }

  _render() {
    // Parse initial filters
    // so filters are reconstructed when the drawer is reopened
    let initialFilters;

    if (this.initialFiltersValue) {
      try {
        const parsed = parseRansackQuery(this.initialFiltersValue);
        if (parsed.conditions.length > 0) {
          initialFilters = parsed;
        }
      } catch {}
    }

    this.root.render(
      createElement(DynamicFilter, {
        resource: this.resourceValue,
        fields: this.fieldsValue,
        accountId: this.accountIdValue,
        baseUrl: this.baseUrlValue || undefined,
        redirectUrl: this.redirectUrlValue || undefined,
        enableGrouping: this.enableGroupingValue,
        initialFilters: initialFilters,
      }),
    );
  }
}
