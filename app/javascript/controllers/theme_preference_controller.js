import { Controller } from "@hotwired/stimulus";
import {
  enable as enableDarkMode,
  disable as disableDarkMode,
} from "darkreader";
import { currentUser } from "../utils/current_user";
import { patch } from "@rails/request.js";

const DARK_READER_CONFIG = {
  brightness: 100,
  contrast: 100,
  sepia: 0,
};

export default class extends Controller {
  static values = { url: String };
  static targets = ["option"];

  connect() {
    this.theme = currentUser().theme_preference || "system";
    this.applyTheme(this.theme);
    this.updateSelection(this.theme);
    this.systemMediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    this.handleSystemChange = this.handleSystemChange.bind(this);
    if (this.theme === "system") {
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
    if (theme === this.theme) return;

    this.theme = theme;
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
      option.classList.toggle("ring-light-palette-p3", isSelected);
      option.classList.toggle("border-transparent", isSelected);
      option.classList.toggle("border-light-palette-p3", !isSelected);
    });
  }

  handleSystemChange() {
    this.applyTheme("system");
  }

  persistTheme(theme) {
    patch(this.urlValue, {
      body: JSON.stringify({ user: { theme_preference: theme } }),
      contentType: "application/json",
    });
  }
}
