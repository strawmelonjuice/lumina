/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
document.forms["signup"]["username"].placeholder = funnyRandomUserName();
setTimeout(() => {
  document.forms["signup"]["email"].placeholder =
    `${funnyRandomUserName()}@${fejson.instance.config.interinstance.iid}`;
}, 200);
const submitbutton = document.forms["signup"]["submitbutton"];
function d(a) {
  if (a.data.Ok === true) {
    submitbutton.innerHTML = `<div style="background-image: url('/green-check.svg'); background-repeat: no-repeat; background-size: cover;" class="pl-max pr-max relative h-10 w-10"></div>`;
    document.getElementById("Aaa1").innerText =
      "Sign-up successful! You will be forwarded now.";
    setTimeout(() => {
      window.location.assign("/home/");
    }, 3000);
  } else {
    submitbutton.innerHTML = `<div style="background-image: url('/red-cross.svg'); background-repeat: no-repeat; background-size: cover;" class="pl-max pr-max relative h-10 w-10"></div>`;
    document.getElementById("Aaa1").innerText = a.data.Errorvalue;
    setTimeout(() => {
      submitbutton.innerText = "Sign up";
      submitbutton.removeAttribute("disabled");
    }, 3000);
  }
}

function regstry() {
  submitbutton.innerHTML = `<div style="background-image: url('/spinner.svg'); background-repeat: no-repeat; background-size: cover;" class="pl-max pr-max relative h-10 w-10"></div>`;
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
        username: document.forms["signup"]["username"].value,
        email: document.forms["signup"]["email"].value,
        password: document.forms["signup"]["password"].value,
      })
      .then(d)
      .catch((error) => {
        console.log(error);
      });
  }, 500);
}
