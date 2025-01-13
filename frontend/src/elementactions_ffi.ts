/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 *
 */

/**
 * TypeScript FFI module providing DOM manipulation and window utilities for the Gleam frontend.
 * This module serves as a bridge between Gleam and browser-specific JavaScript functionality.
 */

export function disableElement(element: HTMLElement) {
	element.setAttribute("disabled", "");
}
export function elementHidden(element: HTMLElement): boolean {
	return element.classList.contains("hidden");
}
export function enableElement(element: HTMLElement) {
	element.removeAttribute("disabled");
}
export function unHideElement(element: HTMLElement) {
	if (element.classList.contains("hidden")) {
		element.classList.remove("hidden");
	}
}
export function hideElement(element: HTMLElement) {
	if (!element.classList.contains("hidden")) {
		element.classList.add("hidden");
	}
}
export function getWindowHost() {
	return window.location.host;
}
export function goWindowBack() {
	return window.history.back();
}
export function setWindowLocationHash(to: string) {
	return (window.location.hash = to);
}
export function getWindowLocationHash() {
	return window.location.hash;
}
export function getValue(elem: HTMLInputElement) {
	return elem.value;
}
