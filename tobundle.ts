// @ts-ignore
import Bun from "bun";
switch (process.argv[2]) {
	case "js-1":
		{
			const pat = process.argv[3];
			let js: string = await Bun.file(pat).text();
			js = `${js}\n\n\n/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Part of project Lumina.
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
`;
			await Bun.write(pat, js);
		}
		break;
	case "css-1":
		{
			// Mostly just to remove that "empty value" error.
			const pat = process.argv[3];
			let css: string = await Bun.file(pat).text();
			css = `/*!
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Part of project Lumina.
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 * 
 * Mainly generated using TailwindCSS!
 */
\n\n\n${css.replaceAll(":  ;", ": unset;").replaceAll(": ;", ": unset;").replaceAll("/*!", "/*")}`;
			await Bun.write(pat, css);
		}
		break;
	default:
		console.log("No valid run subcommand was given.");
}
