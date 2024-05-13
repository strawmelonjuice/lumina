/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
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
		pages: {
			mobile: document.getElementById("mobile-pages-nav"),
			desktop: document.getElementById("pages-nav"),
			location: "pages",
			navigator: true,
		},
		"pages-editor": {
			mobile: document.getElementById("mobile-pages-nav"),
			desktop: document.getElementById("pages-nav"),
			location: "pages-editor",
			navigator: false,
			f: () => {
				const g = document.getElementById("whatamiediting");
				if (getParams().new !== undefined) {
					g.innerText = "Creating a new publication!";
					return;
				}
				if (getParams().id === undefined) {
					g.innerText = "... with nothing open.";
					return;
				}
				if (getParams().id !== undefined) {
					g.innerHTML = `Editing <i><b>${getParams().id}</b></i>!`;
					return;
				}
			},
		},
		addplugin: {
			mobile: document.getElementById("mobile-plugins-nav"),
			desktop: document.getElementById("plugins-nav"),
			location: "addplugin",
			navigator: false,
		},
		notifications: {
			mobile: document.getElementById("mobile-notifications-nav"),
			desktop: document.getElementById("notifications-nav"),
			location: "notifications-centre",
			navigator: true,
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
				.then((response) => {
					document.querySelector("main div#mainright").innerHTML =
						response.data.main;
					document.querySelector("main div#mainleft").innerHTML =
						response.data.side;
					if (window.location.hash === "") window.location.hash = to;
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
				})
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
					"text-gray-300 hover:bg-gray-700 hover:text-white block rounded-md px-3 py-2 text-base font-medium",
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

function LogOut() {
	localStorage.clear();
	window.location.assign("/session/logout");
}

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

function showMobiletimelineSwitcher() {
	document.getElementById("mainright").innerHTML =
		document.getElementById("mainleft").innerHTML;
	document.getElementById("mobiletimelineswitcher").classList.add("hidden");
}
function switchTimeline(tid) {
	console.log(`Switching to timeline with ID string: ${tid}`);
	document.getElementById("mobiletimelineswitcher").classList.remove("hidden");
}
document
	.getElementById("mobiletimelineswitcher")
	.setAttribute("onclick", "showMobiletimelineSwitcher()");
window.on_mobile_swipe_right.push(() => {
	showMobiletimelineSwitcher();
});

window.on_mobile_swipe_down.push(() => {
	window.mobileMenuToggle();
});
// Can't do this, scroll-swiping would be detected
// window.on_mobile_swipe_up.push(() => {
// 	switchpages(hashIsolated());
// });

for (e of document.getElementsByClassName("svg_activenotification")) {
	e.style.display = "none";
}
