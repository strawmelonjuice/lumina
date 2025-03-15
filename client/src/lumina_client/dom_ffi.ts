export function get_color_scheme() {
	// Media queries the preferred color colorscheme

	if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
		return "dark";
	}
	return "light";
}
