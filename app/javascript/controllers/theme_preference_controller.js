import { Controller } from "@hotwired/stimulus";
import {
  enable as enableDarkMode,
  disable as disableDarkMode,
} from "darkreader";

const DARK_READER_CONFIG = {
  brightness: 115,
  contrast: 115,
  sepia: 0,
};

export default class extends Controller {
  static values = { current: String, url: String };
  static targets = ["option"];

  connect() {
    this.applyTheme(this.currentValue);
    this.updateSelection(this.currentValue);
    this.systemMediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    this.handleSystemChange = this.handleSystemChange.bind(this);
    if (this.currentValue === "system") {
      this.systemMediaQuery.addEventListener("change", this.handleSystemChange);
    }
  }

  disconnect() {
    this.systemMediaQuery?.removeEventListener(
      "change",
      this.handleSystemChange,
    );
  }

  select(event) {
    const theme = event.currentTarget.dataset.theme;
    if (theme === this.currentValue) return;

    this.currentValue = theme;
    this.applyTheme(theme);
    this.updateSelection(theme);

    this.systemMediaQuery?.removeEventListener(
      "change",
      this.handleSystemChange,
    );
    if (theme === "system") {
      this.systemMediaQuery.addEventListener("change", this.handleSystemChange);
    }

    if (this.urlValue) {
      this.persistTheme(theme);
    }
  }

  applyTheme(theme) {
    let shouldBeDark = theme === "dark";
    if (theme === "system") {
      shouldBeDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    }

    if (shouldBeDark) {
      enableDarkMode(DARK_READER_CONFIG);
    } else {
      disableDarkMode();
    }
  }

  updateSelection(theme) {
    if (!this.hasOptionTarget) return;

    this.optionTargets.forEach((option) => {
      const isSelected = option.dataset.theme === theme;
      option.classList.toggle("ring-2", isSelected);
      option.classList.toggle("ring-blue-500", isSelected);
      option.classList.toggle("border-blue-500", isSelected);
      option.classList.toggle("border-light-palette-p3", !isSelected);
    });
  }

  handleSystemChange() {
    this.applyTheme("system");
  }

  persistTheme(theme) {
    const csrfToken = document.querySelector(
      'meta[name="csrf-token"]',
    )?.content;

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        Accept: "application/json",
      },
      body: JSON.stringify({ user: { theme_preference: theme } }),
    });
  }
}
