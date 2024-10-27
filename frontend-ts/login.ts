/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

// List of pages login.js is allowed to refer users to.
import axios from "axios";
import { funnyRandomUserName } from "./app";

const loginPageList = ["home", "notifications", "test"];
export const login = () => {
	document.forms[0]["username"].placeholder = funnyRandomUserName();

	const submitbutton = document.forms[0]["submitbutton"];

	function c(a: { data: { Ok: boolean } }, b = false) {
		const allowedPage = (() => {
			let p = "";
			for (const page of loginPageList) {
				if (window.location.hash === `#${page}`) {
					p = page;
				}
			}
			return p;
		})();

		if (a.data.Ok === true) {
			if (b) {
				console.log("autologin success.");
				window.location.replace(`/#${allowedPage}`);
				if (!window.location.pathname.startsWith("/login")) {
					window.location.reload();
				}
				return;
			}
			submitbutton.innerHTML = `<div style="background-image: url('/green-check.svg'); background-repeat: no-repeat; background-size: cover;" class="relative w-10 h-10 pl-max pr-max"></div>`;
			document.getElementById("Aaa1").innerText =
				"Login successful, you will be forwarded now.";

			if (document.forms[0]["autologin"].checked) {
				console.log("Attempting to save credentials");
				window.localStorage.setItem(
					"AutologinUsername",

					document.forms[0]["username"].value,
				);
				window.localStorage.setItem(
					"AutologinMethod",
					document.forms[0]["password"].value,
				);
			}
			setTimeout(() => {
				window.location.assign(`/home/#${allowedPage}`);
			}, 800);
		} else {
			if (b) return;
			submitbutton.innerHTML = `<div style="background-image: url('/red-cross.svg'); background-repeat: no-repeat; background-size: cover;" class="relative w-10 h-10 pl-max pr-max"></div>`;
			document.getElementById("Aaa1").innerText =
				"Something went wrong. Did you enter the correct credentials?";
			setTimeout(() => {
				submitbutton.innerText = "Authorize";
				submitbutton.removeAttribute("disabled");
			}, 3000);
		}
	}

	function authtry() {
		console.log("Trying authentication...");
		submitbutton.innerHTML = `<div style="background-image: url('/spinner.svg'); background-repeat: no-repeat; background-size: cover;" class="relative w-10 h-10 pl-max pr-max"></div>`;
		submitbutton.setAttribute("disabled", "");
		setTimeout(() => {
			submitbutton.innerText = "Retry";
			submitbutton.removeAttribute("disabled");
		}, 9600);
		document.getElementById("Aaa1").innerText = "Checking credentials...";

		// timeout to allow spinner to show up
		setTimeout(() => {
			let bodyFormData = new FormData();
			bodyFormData.set("username", document.forms[0]["username"].value);
			bodyFormData.set("password", document.forms[0]["password"].value);
			axios({
				method: "post",
				url: "/api/fe/auth/",
				data: bodyFormData,
				headers: { "Content-Type": "multipart/form-data" },
			})
				.then(c)
				.catch((error) => {
					console.log(error);
				});
		}, 500);
	}

	document.querySelector("form#loginform").addEventListener("submit", authtry);

	if (localStorage.getItem("AutologinUsername") !== null) {
		console.log("trying autologin...");

		document.forms[0]["username"].value =
			localStorage.getItem("AutologinUsername");

		document.forms[0]["password"].value =
			localStorage.getItem("AutologinMethod");
		authtry();
	}
	window.on_mobile_swipe_down.push(() => {
		window.mobileMenuToggle();
	});
};
