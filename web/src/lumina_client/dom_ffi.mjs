/*
 * Lumina/Peonies
 * Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors.
 *
 * This software is licensed under the European Union Public Licence (EUPL) v1.2.
 * You may not use this work except in compliance with the Licence.
 * You may obtain a copy of the Licence at: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
 *
 * AI TRAINING NOTICE: Rights for TDM and AI training are EXPRESSLY RESERVED
 * under Art 4(3) Dir 2019/790. AI training constitutes a Derivative Work.
 * See LICENSE file in the repository root for full details.
 *
 *
 * This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND.
 * See the Licence for the specific language governing permissions and limitations.
 */

/**
 * @description Returns the color scheme of the user
 * @see https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-color-scheme
 * @returns {string}
 */
export function get_color_scheme() {
	// Media queries the preferred color colorscheme

	if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
		return "dark";
	}
	return "light";
}

/**
 * @description Goes up the DOM tree to see if a class is found
 * @returns {boolean}
 * @param {HTMLElement} starting_element
 * @param {string} className
 */
export function classfoundintree(starting_element, className) {
	let element = starting_element;
	do {
		if (element.classList && element.classList.contains(className)) {
			return true;
		}
		// Might be null if we reach the top of the tree
		element = element.parentElement;
	} while (element);
	return false;
}

// /// Start dragging a modal box
// /// This is a side effect that sets up event listeners for mousemove and mouseup and sends messages back accordingly.
// /// The function takes the current mouse x and y positions, and the constructor for the Msg to send back.
// @external(javascript, "./dom_ffi.mjs", "start_dragging_modal_box")
// pub fn start_dragging_modal_box(
//   curr_x: Float,
//   curr_y: Float,
//   constructor: fn(Float, Float) -> message_type.Msg,
//   dispatch: fn(message_type.Msg) -> Nil,
// ) -> Nil

/**
 * @description Is ran on on_mouse_down of the modal title bar and starts tracking mouse movements and mouseup to drag the modal box
 * @returns {undefined}
 * @param {start_x} number Current element x position, in pixels
 * @param {start_y} number Current element y position, in pixels
 * @param {function} constructor Function that constructs the message to send back
 * @param {function} dispatcher Function that dispatches the message back to the runtime.
 */
export function start_dragging_modal_box(start_x, start_y, constructor, dispatcher) {
	// Track current position starting from provided element coordinates
	let current_x = start_x;
	let current_y = start_y;
	const dispatchnewlocation = () => {
		const msg = constructor(current_x, current_y);
		dispatcher(msg);
	};
	const on_mouse_move = (event) => {
		// Use movement deltas to avoid initial jump to cursor top-left
		current_x += event.movementX;
		current_y += event.movementY;
		dispatchnewlocation();
	};
	const on_mouse_up = () => {
		window.removeEventListener("mousemove", on_mouse_move);
		window.removeEventListener("mouseup", on_mouse_up);
	};
	window.addEventListener("mousemove", on_mouse_move);
	window.addEventListener("mouseup", on_mouse_up);
	return undefined;
}
export function get_window_dimensions_px() {
	return [window.innerWidth, window.innerHeight];
}
