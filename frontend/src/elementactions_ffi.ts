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

export function enableElement(element: HTMLElement) {
	element.removeAttribute("disabled");
}

export function getWindowHost() {
	return window.location.host;
}
