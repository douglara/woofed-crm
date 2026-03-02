import { Controller } from "@hotwired/stimulus";
import { createElement } from "react";
import { createRoot } from "react-dom/client";
import { DynamicFilter } from "@/components/filters";
import { parseRansackParams } from "@/components/filters/ransack-builder";

export default class extends Controller {
  static values = {
    resource: { type: String, default: "deals" },
    fields: { type: Array, default: [] },
    accountId: Number,
    baseUrl: { type: String, default: "" },
    redirectUrl: { type: String, default: "" },
    enableGrouping: { type: Boolean, default: false },
  };

  connect() {
    this.root = createRoot(this.element);
    this._render();
  }

  disconnect() {
    this.root?.unmount();
  }

  _render() {
    // Parse initial filters from the redirect_url's query params
    // so filters are reconstructed when the drawer is reopened
    let initialFilters;
    if (this.redirectUrlValue) {
      try {
        const url = new URL(this.redirectUrlValue, window.location.origin);
        const parsed = parseRansackParams(url.searchParams);
        if (parsed.conditions.length > 0) {
          initialFilters = parsed;
        }
      } catch {
        // ignore invalid URL
      }
    }

    this.root.render(
      createElement(DynamicFilter, {
        resource: this.resourceValue,
        fields: this.fieldsValue,
        accountId: this.accountIdValue,
        baseUrl: this.baseUrlValue || undefined,
        redirectUrl: this.redirectUrlValue || undefined,
        enableGrouping: this.enableGroupingValue,
        initialFilters,
      }),
    );
  }
}
