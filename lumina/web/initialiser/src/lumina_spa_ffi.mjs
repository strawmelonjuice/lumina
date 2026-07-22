import { Result$Ok, Result$Error } from "./gleam";

// localStorage helpers
export function getSessionRevivekey() {
	let val = window.localStorage.getItem("sessionrevive");
	if (val !== null) {
		return Result$Ok(val);
	} else {
		return Result$Error(null);
	}
}
export function storeSessionRevivekey(c) {
	window.localStorage.setItem("sessionrevive", c);
}

// Timer helper
export function with_timeout(delay, cb) {
	return window.setTimeout(cb, delay);
}
