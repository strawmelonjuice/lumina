
/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

// These variables are passed down from the server.

const ephewvar = {"config":{"interinstance":{"iid":"example.com"}}}; // Default config's JSON, to allow editor type chekcking.

// Start of actual site.js

console.log(`Ephew Instance ID: ${ephewvar.config.interinstance.iid}`);
