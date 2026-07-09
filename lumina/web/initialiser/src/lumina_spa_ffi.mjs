import { Result$Ok, Result$Error } from "./gleam";

// localStorage helpers
export function getSessionRevivekey() {
 let val = window.localStorage.getItem("sessionrevive")
 if (val !== null) {
    return Result$Ok(val);
  } else {
    return Result$Error(null);
  }
}

// Timer helper
export function with_timeout(delay, cb) {
  return window.setTimeout(cb, delay);
}

// Console log helpers
export function logLog(any) {
  console.log("[lumina_spa] ", any)
}
export function logInfo(any) {
  console.info("[lumina_spa] ", any)
}
export function logWarn(any) {
  console.warn("[lumina_spa] ", any)
}
export function logError(any) {
  console.warn("[lumina_spa] ", any)
}
