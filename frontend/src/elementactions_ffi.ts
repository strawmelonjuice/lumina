/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 *
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
