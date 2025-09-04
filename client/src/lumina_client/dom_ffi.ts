export function get_color_scheme() {
	// Media queries the preferred color colorscheme

	if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
		return "dark";
	}
	return "light";
}

export function classfoundintree(
	starting_element: HTMLElement,
	className: string,
): boolean {
	let element: HTMLElement | null = starting_element;
	do {
		if (element.classList && element.classList.contains(className)) {
			return true;
		}
		element = element.parentElement as HTMLElement | null;
	} while (element);
	return false;
}
