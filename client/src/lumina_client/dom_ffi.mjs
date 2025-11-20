/*
 *     Lumina/Peonies
 *     Copyright (C) 2018-2026 MLC 'Strawmelonjuice'  Bloeiman and contributors.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
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
