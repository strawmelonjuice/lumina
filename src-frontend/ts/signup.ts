/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
import axios from "axios";
import { funnyRandomUserName } from "./app";

export const signup = () => {
	document.forms[0]["username"].placeholder = funnyRandomUserName();
	setTimeout(() => {
		document.forms[0]["email"].placeholder = `${funnyRandomUserName()}@${
			window.fejson.instance.config.interinstance.iid
		}`;
	}, 200);

	function checkusername() {
		const inp = document.forms[0]["username"];
		axios
			.post("/api/fe/auth-create/check-username", {
				u: inp.value,
			})
			.then((resp) => {
				if (resp.data.Ok === true) {
					document.getElementById("usernameLabel").innerHTML =
						`Username&emsp;&emsp;<span class="text-green-300">⬅ Username is available!&nbsp;<img src="/green-check.svg" class="inline"></span>`;
				} else {
					switch (resp.data.Why) {
						case "InvalidChars":
							{
								document.getElementById(
									"usernameLabel",
								).innerHTML =
									`Username&emsp;&emsp;<span class="text-red-300">⬅ There are characters in this username that are not allowed!&nbsp;<img src="/red-cross.svg" class="inline"></span>`;
							}
							break;
						case "TooShort":
							{
								document.getElementById(
									"usernameLabel",
								).innerHTML =
									`Username&emsp;&emsp;<span class="text-red-300">⬅ That username is too short!&nbsp;<img src="/red-cross.svg" class="inline"></span>`;
							}
							break;
						case "userExists":
							{
								document.getElementById(
									"usernameLabel",
								).innerHTML =
									`Username&emsp;&emsp;<span class="text-red-300">⬅ Someone already claimed that username!&nbsp;<img src="/red-cross.svg" class="inline" alt="X"></span>`;
							}
							break;
						default: {
							document.getElementById("usernameLabel").innerHTML =
								`Username&emsp;&emsp;<span class="text-red-300">⬅ Username is not available!&nbsp;<img src="/red-cross.svg" class="inline" alt="X"></span>`;
						}
					}
				}
			})
			.catch((error) => {
				console.log(error);
				document.getElementById("usernameLabel").innerHTML =
					"Username&emsp;&emsp;⬅ Error while checking this username!";
			});
	}

	document.forms[0]["username"].addEventListener("oninput", checkusername);

	const submitbutton = document.forms[0]["submitbutton"];

	function d(a: { data: { Ok: boolean; Errorvalue: string } }) {
		if (a.data.Ok === true) {
			submitbutton.innerHTML = `<div style="background-image: url('/green-check.svg'); background-repeat: no-repeat; background-size: cover;" class="relative w-10 h-10 pl-max pr-max"></div>`;
			document.getElementById("Aaa1").innerText =
				"Sign-up successful! You will be forwarded now.";
			setTimeout(() => {
				window.location.assign("/home/");
			}, 3000);
		} else {
			submitbutton.innerHTML = `<div style="background-image: url('/red-cross.svg'); background-repeat: no-repeat; background-size: cover;" class="relative w-10 h-10 pl-max pr-max"></div>`;
			document.getElementById("Aaa1").innerText = a.data.Errorvalue;
			setTimeout(() => {
				submitbutton.innerText = "Sign up";
				submitbutton.removeAttribute("disabled");
			}, 3000);
		}
	}

	function regstry() {
		submitbutton.innerHTML = `<div style="background-image: url('/spinner.svg'); background-repeat: no-repeat; background-size: cover;" class="relative w-10 h-10 pl-max pr-max"></div>`;
		submitbutton.setAttribute("disabled", "");
		setTimeout(() => {
			submitbutton.innerText = "Retry";
			submitbutton.removeAttribute("disabled");
		}, 9600);
		document.getElementById("Aaa1").innerText = "Creating account...";

		// timeout to allow spinner to show up
		setTimeout(() => {
			axios
				.post("/api/fe/auth-create", {
					username: document.forms[0]["username"].value,

					email: document.forms[0]["email"].value,

					password: document.forms[0]["password"].value,
				})
				.then(d)
				.catch((error) => {
					console.log(error);
				});
		}, 500);
	}

	document
		.querySelector("form#registrationform")
		.addEventListener("submit", regstry);

	window.on_mobile_swipe_down.push(() => {
		window.mobileMenuToggle();
	});
};
