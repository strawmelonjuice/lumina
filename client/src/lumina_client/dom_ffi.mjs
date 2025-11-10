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
