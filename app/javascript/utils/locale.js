export function getBrowserLocale() {
  return (navigator.language || navigator.languages[0] || "en")
    .toLowerCase()
    .replace("_", "-");
}

export function getBrowserTimeZone() {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}

export function getUserLocale() {
  return document.body.dataset.userLocale;
}

export function getAccountCurrency() {
  return document.body.dataset.accountCurrency;
}
