import { getTimeZone } from "./locale";

export function setBrowserTimezoneCookie() {
  document.addEventListener("DOMContentLoaded", () => {
    document.cookie = `browser_timezone=${getTimeZone()}; path=/`;
  });
}
