/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

const subPageList = {
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
		mobile: document.getElementById("mobile-home-nav"),
		desktop: document.getElementById("home-nav"),
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

function editorfold() {
	document.querySelector("div#posteditor").classList.add("hidden");
	if (document.body.dataset.editorOpen === undefined) {
		document.body.dataset.editorOpen = "initial";
	} else {
		document.body.dataset.editorOpen = "false";
	}
}
function triggerEditor() {
	if (
		document.body.dataset.editorOpen !== "true" &&
		window.location.hash === "#editor"
	) {
		// editor glitched out, going back to retry...
		console.log("triggerEditor: retrying...");
		window.history.back();
		// wait a bit before retrying...
		setTimeout(() => {
			window.location.hash = "editor";
		}, 600);
		return;
	}
	if (document.body.dataset.editorOpen !== "true") {
		window.location.hash = "editor";
	} else {
		console.log(
			"triggerEditor got called, but editor is already open. Refolding editor instead.",
		);
		editorfold();
	}
}
function renderMarkdownLong() {
	if (document.getElementById("editor-long-input").value === "") {
		document.getElementById("editor-long-preview").innerHTML =
			`<p class="w-full h-full text-neutral-400 dark:stroke-stone-400">Click here to start writing! Use markdown to style!</p>`;
		return;
	}
	axios
		.post("/api/fe/editor_fetch_markdownpreview", {
			a: document.getElementById("editor-long-input").value,
		})
		.then((response) => {
			if (response.data.Ok === true) {
				document.getElementById("editor-long-preview").innerHTML =
					response.data.htmlContent;
			} else {
				document.getElementById("editor-long-preview").innerText =
					"There was an error rendering the markdown.";
			}
		})
		.catch((error) => {
			console.error(error);
			document.getElementById("editor-long-preview").innerText =
				"There was an error rendering the markdown.";
		});
}
function renderMarkdownShort() {
	document.getElementById("editor-short-preview").innerHTML = document
		.getElementById("editor-short-input")
		.value.replace(/\*\*(.*?)\*\*/g, "<b>$1</b>")
		.replace(/\*(.*?)\*/g, "<i>$1</i>")
		.replace(/_(.*?)_/g, "<i>$1</i>")
		.replace(/~(.*?)~/g, "<del>$1</del>")
		.replace(/\^(.*?)\^/g, "<sup>$1</sup>")
		.replace(
			/`(.*?)`/g,
			`<code class="text-blue-500 bg-slate-200 dark:text-blue-200 dark:bg-slate-600 m-1">$1</code>`,
		);
}
function switcheditormode(elm) {
	const modenames = ["short", "long", "embed"];
	const desiredmode = elm.dataset.modeOpener;
	for (const modename of modenames) {
		// console.log(
		// 	"Desired mode: " + desiredmode + "\nIterated mode: " + modename,
		// );
		const opener = document.querySelector(
			`nav#editormodepicker [data-mode-opener="${modename}"]`,
		);
		const field = document.querySelector(
			`div#editorwindowm [data-mode-field="${modename}"]`,
		);

		if (modename === desiredmode) {
			opener.className =
				"flex items-center justify-center p-0 bg-orange-100 border-2 border-b-0 rounded-md rounded-b-none cursor-default border-emerald-600 dark:text-orange-100 dark:bg-neutral-800 text-brown-800 dark:border-zinc-400";
			field.classList.add("block");
			field.classList.remove("hidden");
		} else {
			opener.className =
				"flex items-center justify-center p-0 border-2 rounded-md cursor-pointer bg-emerald-200 dark:bg-teal-800 border-emerald-600 dark:text-orange-100 hover:text-white hover:bg-gray-700 text-brown-800 dark:border-zinc-400";
			field.classList.add("hidden");
			field.classList.remove("block");
		}
	}
	switch (desiredmode) {
		case "short":
			{
				document
					.getElementById("editor-short-input")
					.addEventListener("change", renderMarkdownShort);
				setInterval(renderMarkdownShort, 400);
				renderMarkdownShort();

				document.addEventListener("keydown", (ev) => {
					if (
						ev.key === "Enter" &&
						document.activeElement ===
							document.getElementById("editor-short-container")
					) {
						document.getElementById("editor-short-input").focus();
					} else if (
						ev.key === "Escape" &&
						document.activeElement ===
							document.getElementById("editor-short-input")
					) {
						document.activeElement.blur();
					}
				});

				document
					.getElementById("editor-short-container")
					.addEventListener("click", () => {
						document.getElementById("editor-short-input").focus();
					});
				document.getElementById("editor-short-input").focus();
			}
			break;
		case "long":
			{
				document
					.getElementById("editor-long-input")
					.addEventListener("change", renderMarkdownLong);
				renderMarkdownLong();

				document.addEventListener("keydown", (ev) => {
					if (
						ev.key === "Enter" &&
						document.activeElement ===
							document.getElementById("editor-long-container")
					) {
						document.getElementById("editor-long-input").focus();
					} else if (
						ev.key === "Escape" &&
						document.activeElement ===
							document.getElementById("editor-long-input")
					) {
						document.activeElement.blur();
					}
				});

				document
					.getElementById("editor-long-container")
					.addEventListener("click", () => {
						document.getElementById("editor-long-input").focus();
					});
				document.getElementById("editor-long-input").focus();
			}
			break;
		default:
			break;
	}
}
function editorunfold() {
	document.getElementById("mobiletimelineswitcher").classList.add("hidden");
	document.getElementById("posteditor").classList.remove("hidden");
	const errormsg = `<p class="w-full h-full text-black bg-white dark:text-white dark:bg-black">
				Failed to load post editor.
			</p>`;
	if (document.body.dataset.editorOpen === "initial") {
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
					 * @property {string} main Main HTML from the source.
					 * @property {string} side Sidebar HTML from the source.
					 * @property {number[]} message Messages from the source.
					 * # Meanings
					 * - 1: Session invalid
					 * - 2: Source unknown (404)
					 */
					if (
						!response.data.message.includes(2) &&
						!response.data.message.includes(1)
					) {
						document.querySelector("div#posteditor").innerHTML =
							response.data.main;
						window.history.back();
					} else {
						document.querySelector("div#posteditor").innerHTML =
							error;
					}
					document
						.querySelector("button#bttn_closeeditor")
						.setAttribute("onclick", "editorfold()");
					document
						.querySelector("main")
						.setAttribute("onclick", "editorfold()");
					switcheditormode(
						document.querySelector(
							"nav#editormodepicker [data-mode-opener='short']",
						),
					);
				},
			)
			.catch((error) => {
				document.querySelector("div#posteditor").innerHTML = errormsg;
				console.error(error);
				
			});
	}
	setTimeout(() => {
		window.dragEditor = (e) => {
			e.preventDefault();
			window.editorposition3 = e.clientX;
			window.editorposition4 = e.clientY;
			document.onmouseup = window.stopEditorDragging;
			document.onmousemove = window.editorDrag;
		};
		window.editorDrag = (e) => {
			e.preventDefault();
			window.editorposition1 = window.editorposition3 - e.clientX;
			window.editorposition2 = (() => {
				const o = window.editorposition4 - e.clientY;
				if (
					document.querySelector("div#posteditor").offsetTop - o <
					20
				) {
					return (
						document.querySelector("div#posteditor").offsetTop - 40
					);
				}
				return o;
			})();
			window.editorposition3 = e.clientX;
			window.editorposition4 = e.clientY;
			document.querySelector("div#posteditor").style.top = `${
				document.querySelector("div#posteditor").offsetTop -
				window.editorposition2
			}px`;
			document.querySelector("div#posteditor").style.left = `${
				document.querySelector("div#posteditor").offsetLeft -
				window.editorposition1
			}px`;
		};

		window.stopEditorDragging = () => {
			document.onmouseup = null;
			document.onmousemove = null;
		};
		document.getElementById("editorwindowh").onmousedown =
			window.dragEditor;

		document.body.dataset.editorOpen = "true";
	}, 100);
}

/**
 * description placeholder
 *
 * @param {string} toPageName
 */
function switchpages(toPageName) {
	let to = toPageName;
	if (toPageName === "") to = "home";

	for (const d in subPageList) {
		const a = subPageList[d];
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
								`/login#${window.location.hash.replace(
									window.location.hash.split("?")[0],
									to,
								)}`,
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
	if (document.body.dataset.editorOpen !== "true") {
		if (event.key === "e") {
			event.preventDefault();
			triggerEditor();
		}
		if (event.key === "h") {
			event.preventDefault();
			window.location.hash = "home";
		}
		if (event.key === "n") {
			event.preventDefault();
			window.location.hash = "notifications";
		}
	}
});

/**
 * description placeholder
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
		// console.log("Automatically switching this page up.");
		if (hashIsolated() === "editordirect") {
			triggerEditor();
		} else {
			switchpages(hashIsolated());
		}
	}
}, 100);

/**
 * description placeholder
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
		if (f !== null && f !== undefined) {
			f.setAttribute("alt", fejson.user.username);
		}
	}
	for (const a of document.getElementsByClassName("settodisplayname")) {
		// a.innerText = fejson.user.displayname;
		a.innerText = fejson.user.username;
	}
});

/**
 * description placeholder
 */
function LogOut() {
	localStorage.clear();
	window.location.assign("/session/logout");
}

/**
 * description placeholder
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
 * description placeholder
 */
function showMobiletimelineSwitcher() {
	document.getElementById("mainright").innerHTML =
		document.getElementById("mainleft").innerHTML;
	document.getElementById("mobiletimelineswitcher").classList.add("hidden");
}

/**
 * description placeholder
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
	eve.preventDefault();
	showMobiletimelineSwitcher();
});

window.on_mobile_swipe_down.push((eve) => {
	eve.preventDefault();
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
	for (const e of document.getElementsByClassName("unparsed-timestamp")) {
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
// Fold up the new post editor
editorfold();
