// @ts-ignore
import Bun from "bun";
const pat = "./target/generated/js/app.js";
let js: string = await Bun.file(pat).text();
js = js + "\n\n\n" +
`/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Part of project Lumina.
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
`;
await Bun.write(pat, js);