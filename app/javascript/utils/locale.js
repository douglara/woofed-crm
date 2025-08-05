export function getBrowserLocale() {
  return (navigator.language || navigator.languages[0] || "en")
    .toLowerCase()
    .replace("_", "-");
}

export function getTimeZone() {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}
