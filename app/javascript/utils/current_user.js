import { getMetaJSON } from "./meta";

let cachedUser = null;

function loadCurrentUser() {
  if (!cachedUser) {
    cachedUser = getMetaJSON("user-data") || {};
  }
  return cachedUser;
}

export function currentUser() {
  return loadCurrentUser();
}

export function isLoggedIn() {
  return !!currentUser().id;
}
