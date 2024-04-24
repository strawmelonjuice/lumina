/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

import axios from "../../../node_modules/axios/index";


const axi = axios;

// These variables are passed down from the server.
const ephewvar = { config: { interinstance: { iid: "example.com" } } }; // Default config's JSON, to allow editor type chekcking.

// Start of actual site.js

axi.get("Dokspa").then(() => {
	console.log(" awhat");
});

console.log(`Ephew Instance ID: ${ephewvar.config.interinstance.iid}`);
/*
// Disabled code from Cynthia-dash
let GeneralSiteInfo;


function pullpoll() {
	axios 
		.get("/api/GeneralSiteInfoPoll")
		.then((response: { data: any; }) => {
			GeneralSiteInfo = response.data;
			GeneralSiteInfo.client = {};
			putpoll();
		})
		.catch((error) => {
			console.error(error);
		});
}

pullpoll();
setInterval(pullpoll, 30000);
window.pollers = [
	() => {
		for (const a of document.getElementsByClassName("refertohomesite")) {
			a.setAttribute("href", GeneralSiteInfo.parentnodeadress);
		}
	},
];

function putpoll() {
	pollers.forEach((o) => {
		o();
	});
}

setTimeout(function () {
	setInterval(putpoll);
}, 80);
*/

function getParams() {
	const s = {};
	if (window.location.hash.split("?")[1] === undefined) return s;
	const o = window.location.hash.split("?")[1].split("&");
	for (const x of o) {
		const p = x.split("=");
		const q = p[0];
		// @ts-expect-error
		s[q] = p[1];
	}
	return s;
}
