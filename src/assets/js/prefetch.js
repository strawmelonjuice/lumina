/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

/**
 * @description These variables are passed down from the server.
 * @global
 * @type {{ instance: { config: { interinstance: { iid: string; lastpoll: number; }; }; }; user: { username: string; id: number; }; }}
 */
let fejson = {};

setInterval(pulls, 30000);
const pulled = [
	() => {
		for (const a of document.getElementsByClassName("ownuserprofilelink")) {
			a.setAttribute("href", `/user/${fejson.user.username}/me`);
		}
	},
	() => {
		for (const e of document.getElementsByClassName("placeholder-iid")) {
			e.innerHTML = fejson.instance.config.interinstance.iid;
		}
	},
];

/**
 * Description placeholder
 */
function putpulls() {
	for (o of pulled) {
		o();
	}
}

setTimeout(() => {
	setInterval(putpulls);
}, 80);
/**
 * Turns GET params into an object.
 *
 * @returns {{}}
 */
function getParams() {
	const s = {};
	if (window.location.hash.split("?")[1] === undefined) return s;
	const o = window.location.hash.split("?")[1].split("&");
	for (const x of o) {
		const p = x.split("=");
		const q = p[0];
		s[q] = p[1];
	}
	return s;
}
/**
 * Description placeholder
 */
function pulls() {
	axios
		.get("/api/fe/update")
		.then((response) => {
			fejson = response.data;
			putpulls();
		})
		.catch((error) => {
			console.error(error);
		});
}
pulls();

function randomStringFromArray(array) {
	return array[Math.floor(Math.random() * array.length)];
}

/**
 * Description placeholder
 *
 * @returns {*}
 */
function funnyRandomUserName() {
	const wordsboth = [
		"strawberry",
		"hat",
		"burger",
		"flat",
		"orange",
		"toothpaste",
		"nerd",
		"koala",
		"sample",
	];
	const wordsfirst = wordsboth.concat([
		"straw",
		"hacker",
		"hat",
		"strawberry",
		"apple",
		"rotten",
		"shrimp",
		"feared-",
		"smelly",
	]);
	const wordslast = wordsboth.concat([
		"-bubble",
		"-hat",
		"-man",
		"-bro",
		"-woman",
		"grapes",
		"dancer",
		"salad",
		"hair",
	]);
	return `${randomStringFromArray(wordsfirst)}${randomStringFromArray(
		wordslast
	)}${Math.floor(Math.random() * 10001) + 1000}`.replace("--", "-");
}
