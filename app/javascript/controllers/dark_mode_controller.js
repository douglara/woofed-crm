import { Controller } from "@hotwired/stimulus";
import {
  enable as enableDarkMode,
  disable as disableDarkMode,
  auto as followSystemColorScheme,
  exportGeneratedCSS as collectCSS,
  isEnabled as isDarkReaderEnabled,
} from "darkreader";

export default class extends Controller {
  static values = { url: String };
  static targets = ["lightIcon", "darkIcon", "label"];

  initialize() {
    enableDarkMode({
      brightness: 100,
      contrast: 100,
      sepia: 0,
    });
  }
  toggle() {
    const html = document.documentElement;
    const isDark = html.classList.toggle("dark");

    this.lightIconTarget.classList.toggle("hidden", isDark);
    this.darkIconTarget.classList.toggle("hidden", !isDark);

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = isDark ? "Light" : "Dark";
    }

    const csrfToken = document.querySelector(
      'meta[name="csrf-token"]',
    )?.content;

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": csrfToken,
        Accept: "application/json",
      },
    });
  }
}
