import Bun from "bun";
switch (process.argv[2]) {
	case "setup-prelude":
		{
			const fs = require("bun:fs");
			const path = require("bun:path");
			const target = path.join(
				__dirname,
				"frontend",
				"build",
				"dev",
				"javascript",
				"prelude.mjs",
			);
			const link = path.join(__dirname, "frontend", "prelude.mjs");
			try {
				fs.symlinkSync(target, link, "file");
				console.log("Prelude symlink created successfully");
			} catch (error) {
				console.error("Failed to create prelude symlink:", error);
			}
		}
		break;
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
