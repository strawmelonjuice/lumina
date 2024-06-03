/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
function editorfold() {
	document.querySelector(
		"div#posteditor",
	).classList.add("hidden");
}

function editorunfold() {
	document
		.getElementById("mobiletimelineswitcher")
		.classList.add("hidden");
	document
		.getElementById("posteditor")
		.classList.remove("hidden");
	const error = `<p class="w-full h-full text-black bg-white dark:text-white dark:bg-black">
				Failed to load post editor.
			</p>`

	axios
		.post("/api/fe/fetch-page", {
			location: "editor",
		})
		.then(
			/**
			 * @param {ResFromSource} response - Represents the response containing an _FEPageServeResponse_ coming from an instance server.
			 */
			(response) => {
				/**
				 * Represents the response containing an _FEPageServeResponse_ coming from an instance server.
				 * @typedef {Object} ResFromSource
				 * @property {FromSource} data - Represents the _FEPageServeResponse_ coming from an instance server.
				 */
				/**
				 * Represents the _FEPageServeResponse_ coming from an instance server.
				 * @typedef {Object} FromSource
				 * @property {string} main Main HTML from source.
				 * @property {string} side Sidebar HTML from source.
				 * @property {number[]} message Messages from the source.
				 * # Meanings
				 * - 1: Session invalid
				 * - 2: Source unknown (404)
				 */
				if (!response.data.message.includes(2) && !response.data.message.includes(1)) {
					document.querySelector(
						"div#posteditor",
					).innerHTML = response.data.main;
					window.history.back()
				} else {
					document.querySelector(
						"div#posteditor",
					).innerHTML = error;
				}
				document.querySelector(
					"button#bttn_closeeditor",
				).setAttribute("onclick", "editorfold()");
				
			},
		)
		.catch((error) => {
			document.querySelector(
				"div#posteditor",
			).innerHTML = error;
			console.error(error);
		});
		setTimeout(() => {
			window.dragEditor = (e) => {
				e = e || window.event;
				e.preventDefault();
				// get the mouse cursor position at startup:
				window.editorposition3 = e.clientX;
				window.editorposition4 = e.clientY;
				document.onmouseup = window.stopEditorDragging;
				// call a function whenever the cursor moves:
				document.onmousemove = window.editorDrag;
			}
			window.editorDrag = (e) =>  {
				e = e || window.event;
				e.preventDefault();
				window.editorposition1 = window.editorposition3 - e.clientX;
				window.editorposition2 = (function () {
					const o = window.editorposition4 - e.clientY;
					if ((document.querySelector(
						"div#posteditor",
					).offsetTop - o) < 20) {
						return (document.querySelector(
							"div#posteditor",
						).offsetTop - 40);
					} else {
						return o;
					}
					

				})();
				window.editorposition3 = e.clientX;
				window.editorposition4 = e.clientY;
				document.querySelector(
						"div#posteditor",
					).style.top = (document.querySelector(
						"div#posteditor",
					).offsetTop - window.editorposition2) + "px";
					document.querySelector(
							"div#posteditor",
						).style.left = (document.querySelector(
							"div#posteditor",
						).offsetLeft - window.editorposition1) + "px";
			}

			window.stopEditorDragging = ()=> {
				/* stop moving when mouse button is released:*/
				document.onmouseup = null;
				document.onmousemove = null;
			}
			document.getElementById(
				"editorwindowh",
			).onmousedown = window.dragEditor;
		}, 100);
}

/**
 * Description placeholder
 *
 * @param {string} toPageName
 */
function switchpages(toPageName) {
	let to = toPageName;
	if (toPageName === "") to = "home";
	const navbutton = {
		home: {
			mobile: document.getElementById("mobile-home-nav"),
			desktop: document.getElementById("home-nav"),
			location: "home",
			navigator: true,
			f: () => {
				document
					.getElementById("mobiletimelineswitcher")
					.classList.remove("hidden");
			},
		},
		test: {
			mobile: document.getElementById("mobile-test-nav"),
			desktop: document.getElementById("test-nav"),
			location: "test",
			navigator: true,
			f: () => {
				document
					.getElementById("mobiletimelineswitcher")
					.classList.add("hidden");
			},
		},
		editor: {
			mobile: document.getElementById("mobile-test-nav"),
			desktop: document.getElementById("test-nav"),
			location: "editor",
			navigator: false,
			f: editorunfold,
		},
		notifications: {
			mobile: document.getElementById("mobile-notifications-nav"),
			desktop: document.getElementById("notifications-nav"),
			location: "notifications-centre",
			navigator: true,
			f: () => {
				document
					.getElementById("mobiletimelineswitcher")
					.classList.add("hidden");
			},
		},
	};
	for (const d in navbutton) {
		const a = navbutton[d];
		if (a.navigator) {
			for (const h of [a.mobile, a.desktop]) {
				h.setAttribute("onclick", `switchpages("${d}")`);
			}
		}
		if (d === to) {
			a.mobile.setAttribute(
				"class",
				"bg-red-400 dark:bg-red-900 text-white block rounded-md px-3 py-2 text-base font-medium",
			);
			a.desktop.setAttribute(
				"class",
				"border-2 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-md",
			);
			a.ariaCurrent = "page";
			axios
				.post("/api/fe/fetch-page", {
					location: a.location,
				})
				.then(
					/**
					 * @param {ResFromSource} response - Represents the response containing an _FEPageServeResponse_ coming from an instance server.
					 */
					(response) => {
						/**
						 * Represents the response containing an _FEPageServeResponse_ coming from an instance server.
						 * @typedef {Object} ResFromSource
						 * @property {FromSource} data - Represents the _FEPageServeResponse_ coming from an instance server.
						 */
						/**
						 * Represents the _FEPageServeResponse_ coming from an instance server.
						 * @typedef {Object} FromSource
						 * @property {string} main Main HTML from source.
						 * @property {string} side Sidebar HTML from source.
						 * @property {number[]} message Messages from the source.
						 * # Meanings
						 * - 1: Session invalid
						 * - 2: Source unknown (404)
						 * - 33: Do not replace sidebar (keep it as is)
						 * - 34: Do not replace either (keep it as is)
						 */
						if (!response.data.message.includes(34)) {
							document.querySelector(
								"main div#mainright",
							).innerHTML = response.data.main;
						}
						if (
							!response.data.message.includes(33) &&
							!response.data.message.includes(34)
						) {
							document.querySelector(
								"main div#mainleft",
							).innerHTML = response.data.side;
						}
						if (response.data.message.includes(1)) {
							window.location.assign(
								`/login#${window.location.hash.replace(window.location.hash.split("?")[0], to)}`,
							);
						}
						if (window.location.hash === "")
							window.location.hash = to;
						else {
							window.location.hash = window.location.hash.replace(
								window.location.hash.split("?")[0],
								to,
							);
						}
						window.displayedPage = to;
						if (a.f !== undefined) {
							a.f();
						}
					},
				)
				.catch((error) => {
					document.querySelector("main div#mainright").innerHTML =
						"There was an error loading this page.";
					document.querySelector("main div#mainleft").innerHTML = "";
					console.error(error);
				});
		} else {
			if (a.navigator) {
				a.mobile.setAttribute(
					"class",
					"block rounded-md px-3 py-2 text-base font-medium bg-orange-200 text-brown-800 dark:text-orange-200 border-emerald-600 dark:bg-yellow-700 dark:border-zinc-400 hover:bg-gray-700 hover:text-white",
				);
				a.desktop.setAttribute(
					"class",
					"px-3 py-2 text-sm font-medium bg-orange-200 border-2 rounded-md text-brown-800 dark:text-orange-200 border-emerald-600 dark:bg-yellow-700 dark:border-zinc-400 hover:bg-gray-700 hover:text-white",
				);
				a.ariaCurrent = "none";
			}
		}
	}
}

document.addEventListener("keydown", (event) => {
	if (event.key === "h") {
		event.preventDefault();
		window.location.hash = "home";
	}
	if (event.key === "n") {
		event.preventDefault();
		window.location.hash = "notifications";
	}
});

/**
 * Description placeholder
 *
 * @returns {string}
 */
function hashIsolated() {
	if (window.location.hash === "") return "";
	return window.location.hash.split("#")[1].split("?")[0];
}

setInterval(() => {
	if (
		window.displayedPage === undefined ||
		hashIsolated() !== window.displayedPage
	) {
		console.log("Automatically switching this page up.");
		switchpages(hashIsolated());
	}
}, 100);

/**
 * Description placeholder
 */
function userMenuToggle() {
	const userMenu = document.getElementById("user-menu");
	if (userMenu.classList.contains("hidden")) {
		userMenu.classList.remove("hidden");
	} else {
		userMenu.classList.add("hidden");
	}
}

userMenuToggle();
document
	.getElementById("user-menu-button")
	.setAttribute("onClick", "userMenuToggle()");

window.pulled.push(() => {
	{
		const f = document.getElementById("userimg");
		if (f == null || f !== undefined) {
			f.setAttribute("alt", fejson.user.username);
		}
	}
	for (const a of document.getElementsByClassName("settodisplayname")) {
		// a.innerText = fejson.user.displayname;
		a.innerText = fejson.user.username;
	}
});

/**
 * Description placeholder
 */
function LogOut() {
	localStorage.clear();
	window.location.assign("/session/logout");
}

/**
 * Description placeholder
 *
 * @type {{ "plugins-disabled": { remove: (plugin: any) => void; }; }}
 */
const features = {
	"plugins-disabled": {
		remove: (plugin) => {
			console.log(`${plugin} is being removed`);
			axios
				.post("/api/plugin.remove", {
					plugin: plugin,
				})
				.then((response) => {
					console.log(response.data);
				})
				.catch((error) => {
					console.error(error);
				});
			setTimeout(() => {
				switchpages("plugins");
			}, 800);
		},
	},
};

/**
 * Description placeholder
 */
function showMobiletimelineSwitcher() {
	document.getElementById("mainright").innerHTML =
		document.getElementById("mainleft").innerHTML;
	document.getElementById("mobiletimelineswitcher").classList.add("hidden");
}

/**
 * Description placeholder
 *
 * @param {string} tid Timeline ID to browse to
 */
function switchTimeline(tid) {
	console.log(`Switching to timeline with ID string: ${tid}`);
	document
		.getElementById("mobiletimelineswitcher")
		.classList.remove("hidden");
}

document
	.getElementById("mobiletimelineswitcher")
	.setAttribute("onclick", "showMobiletimelineSwitcher()");
window.on_mobile_swipe_right.push((eve) => {
	eve.preventDefault()
	showMobiletimelineSwitcher();
});

window.on_mobile_swipe_down.push((eve) => {
	eve.preventDefault()
	window.mobileMenuToggle();
});
// Can't do this, scroll-swiping would be detected
// window.on_mobile_swipe_up.push(() => {
// 	switchpages(hashIsolated());
// });

for (e of document.getElementsByClassName("svg_activenotification")) {
	e.style.display = "none";
}

setInterval(() => {
	for (e of document.getElementsByClassName("unparsed-timestamp")) {
		console.log(e.innerText);
		const d = new Date(e.innerText * 1000);
		// var hours = d.getHours();

		// function pad(n) {
		// 	return n < 10 ? '0' + n : n;
		// }
		// const minutes = pad(d.getMinutes());

		// const seconds = pad(d.getSeconds());
		// const formattedTime = hours + ':' + minutes + ':' + seconds;

		e.innerText = d.toLocaleString();
		e.classList.remove("unparsed-timestamp");
		e.classList.add("parsed-timestamp");
		// console.log(formattedTime);
	}
});
editorfold();
