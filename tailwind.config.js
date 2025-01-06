module.exports = {
	content: [
		"./*frontend/**/*.{handlebars,ts,gleam}",
		"./backend/src/lumina/web/**/*.gleam",
		"./backend-rs/src/**/*.rs",
	],
	theme: {
		fontFamily: {
			sans: ["Josefin Sans", "Fira Sans", "sans-serif"],
			serif: [],
		},
		extend: {
			colors: {
				brown: {
					25: "#E9F7F6",
					50: "#fdf8f6",
					100: "#f2e8e5",
					200: "#eaddd7",
					300: "#e0cec7",
					400: "#d2bab0",
					500: "#bfa094",
					600: "#a18072",
					700: "#977669",
					800: "#846358",
					900: "#43302b",
				},
			},
		},
	},
	plugins: [],
};
