/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

document.forms["login"]["username"].placeholder = funnyRandomUserName();
const submitbutton = document.forms["login"]["submitbutton"];
function c(a, b = false) {
  if (a.data.Ok === true) {
    if (b) {
      console.log("autologin success.");
      window.location.replace(`/${window.location.hash}`);
      if (!window.location.pathname.startsWith("/login")) {
        window.location.reload(true);
      }
      return;
    }
    submitbutton.innerHTML = `<div style="background-image: url('/green-check.svg'); background-repeat: no-repeat; background-size: cover;" class="pl-max pr-max relative h-10 w-10"></div>`;
    document.getElementById("Aaa1").innerText =
      "Login successful, you will be forwarded now.";
    if (document.forms["login"]["autologin"].checked) {
      console.log("Attempting to save credentials");
      window.localStorage.setItem(
        "AutologinUsername",
        document.forms["login"]["username"].value,
      );
      window.localStorage.setItem(
        "AutologinPassword",
        document.forms["login"]["password"].value,
      );
    }
    setTimeout(() => {
      window.location.assign(`/home/${window.location.hash}`);
    }, 800);
  } else {
    if (b) return;
    submitbutton.innerHTML = `<div style="background-image: url('/red-cross.svg'); background-repeat: no-repeat; background-size: cover;" class="pl-max pr-max relative h-10 w-10"></div>`;
    document.getElementById("Aaa1").innerText =
      "Something went wrong. Did you enter the correct credentials?";
    setTimeout(() => {
      submitbutton.innerText = "Authorize";
      submitbutton.removeAttribute("disabled");
    }, 3000);
  }
}

function authtry() {
  submitbutton.innerHTML = `<div style="background-image: url('/spinner.svg'); background-repeat: no-repeat; background-size: cover;" class="pl-max pr-max relative h-10 w-10"></div>`;
  submitbutton.setAttribute("disabled", "");
  setTimeout(() => {
    submitbutton.innerText = "Retry";
    submitbutton.removeAttribute("disabled");
  }, 9600);
  document.getElementById("Aaa1").innerText = "Checking credentials...";

  // timeout to allow spinner to show up
  setTimeout(() => {
    axios
      .post("/api/fe/auth", {
        username: document.forms["login"]["username"].value,
        password: document.forms["login"]["password"].value,
      })
      .then(c)
      .catch((error) => {
        console.log(error);
      });
  }, 500);
}

if (localStorage.getItem("AutologinUsername") !== null) {
  console.log("trying autologin...");
  document.forms["login"]["username"].value =
    localStorage.getItem("AutologinUsername");
  document.forms["login"]["password"].value =
    localStorage.getItem("AutologinPassword");
  authtry();
}
window.on_mobile_swipe_down.push(() => {
	window.mobileMenuToggle();
});