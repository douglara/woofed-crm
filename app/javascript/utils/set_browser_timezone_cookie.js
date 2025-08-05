import { getBrowserTimeZone } from "./locale";

export function setBrowserTimezoneCookie() {
  document.addEventListener("DOMContentLoaded", () => {
    document.cookie = `browser_timezone=${getBrowserTimeZone()}; path=/`;
  });
}
