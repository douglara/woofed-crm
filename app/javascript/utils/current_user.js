import { getMetaJSON } from "./meta";

export function currentUser() {
  return getMetaJSON("user-data") || {};
}

export function isLoggedIn() {
  return !!currentUser().id;
}
