/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

import axios from "axios";
import { login } from "./login";
import { signup } from "./signup";
import { siteHome, siteIndex } from "./site";

window.fejson = {
  pulled: 0,
  instance: {
    iid: "",
    lastsync: 0,
  },
  user: { username: "", id: -1 },
};

setInterval(pulls, 30000);
window.pulled = [
  () => {
    for (const a of document.getElementsByClassName("ownuseravatarsrc")) {
      if (a.getAttribute("src") === "") {
        a.setAttribute("src", `/user/avatar/${window.fejson.user.id}`);
      }
    }
  },
  () => {
    for (const a of document.getElementsByClassName("ownuserprofilelink")) {
      a.setAttribute("href", `/user/${window.fejson.user.username}/me`);
    }
  },
  () => {
    for (const e of document.getElementsByClassName("placeholder-iid")) {
      e.innerHTML = window.fejson.instance.iid;
    }
  },
];
pulls();
function putpulls() {
  if (!(window.fejson.pulled === 0)) {
    for (const o of window.pulled) {
      o();
    }
  }
}

setTimeout(() => {
  setInterval(putpulls);
}, 80);

/**
 * description placeholder
 */
function pulls() {
  axios
    .get("/api/fe/update")
    .then((response) => {
      window.fejson = {
        instance: response.data.instance,
        user: response.data.user,
        pulled: Date.now(),
      };
      putpulls();
    })
    .catch((error) => {
      console.error(error);
    });
}

pulls();

function randomStringFromArray(array: string[]) {
  return array[Math.floor(Math.random() * array.length)];
}

/**
 * Generates example usernames
 *
 */
import words from "./json/random-username-parts.json" with { type: "json" };
export function funnyRandomUserName(): string {
  const wordsboth = words.both;
  const wordsfirst = wordsboth.concat(words.first);
  const wordslast = wordsboth.concat(words.last);
  return `${randomStringFromArray(wordsfirst)}${randomStringFromArray(
    wordslast,
  )}${Math.floor(Math.random() * 10001) + 1000}`.replace("--", "-");
}

window.onload = () => {
  window.mobileMenuToggle = () => {
    const mobilemenu = document.getElementById("mobile-menu");
    if (mobilemenu.classList.contains("hidden")) {
      mobilemenu.classList.remove("hidden");
      document.getElementById("btn-mobile-menu-open").classList.add("hidden");
      document
        .getElementById("btn-mobile-menu-close")
        .classList.remove("hidden");
    } else {
      mobilemenu.classList.add("hidden");
      document
        .getElementById("btn-mobile-menu-open")
        .classList.remove("hidden");
      document.getElementById("btn-mobile-menu-close").classList.add("hidden");
    }
  };

  window.mobileMenuToggle();
  document
    .getElementById("btn-mobile-menu")
    .setAttribute("onClick", "window.mobileMenuToggle()");
};
window.on_mobile_swipe_left = [
  (_) => {
    console.log("Swipe left detected");
  },
];
window.on_mobile_swipe_right = [
  (_) => {
    console.log("Swipe right detected.");
  },
];
window.on_mobile_swipe_up = [
  (_) => {
    console.log("Swipe up detected");
  },
];
window.on_mobile_swipe_down = [
  (_) => {
    console.log("Swipe down detected");
  },
];

setTimeout(() => {
  const mainHTML = document.querySelector("main");
  if (mainHTML == null) return;
  mainHTML.addEventListener("touchstart", handleTouchStart, false);
  mainHTML.addEventListener("touchmove", handleTouchMove, false);
}, 300);

let xDown: number = null;
let yDown: number = null;

function getTouches(evt: TouchEvent) {
  return evt.touches;
}

function handleTouchStart(evt: TouchEvent) {
  const firstTouch = getTouches(evt)[0];
  xDown = firstTouch.clientX;
  yDown = firstTouch.clientY;
}

function handleTouchMove(evt: TouchEvent) {
  if (!xDown || !yDown) {
    return;
  }

  const xUp = evt.touches[0].clientX;
  const yUp = evt.touches[0].clientY;

  const xDiff = xDown - xUp;
  const yDiff = yDown - yUp;

  if (Math.abs(xDiff) > Math.abs(yDiff)) {
    /*most significant*/
    if (xDiff > 0) {
      if (window.matchMedia("(max-width: 1024px)").matches) {
        for (const fn of window.on_mobile_swipe_left) {
          fn(evt);
        }
      }
    } else {
      if (window.matchMedia("(max-width: 1024px)").matches) {
        for (const fn of window.on_mobile_swipe_right) {
          fn(evt);
        }
      }
    }
  } else {
    if (yDiff > 0) {
      if (window.matchMedia("(max-width: 1024px)").matches) {
        for (const fn of window.on_mobile_swipe_up) {
          fn(evt);
        }
      }
    } else {
      if (window.matchMedia("(max-width: 1024px)").matches) {
        for (const fn of window.on_mobile_swipe_down) {
          fn(evt);
        }
      }
    }
  }
  /* reset values */
  xDown = null;
  yDown = null;
}
window.addEventListener("DOMContentLoaded", (_event) => {
  // Call page-specific scripts.
  switch (window.location.pathname) {
    case "/login":
    case "/login/":
      login();
      break;
    case "/signup":
    case "/signup/":
      signup();
      break;
    case "/home":
    case "/home/":
      siteHome();
      break;
    default:
      siteIndex();
      break;
  }
});
declare global {
  export interface Window {
    mobileMenuToggle: () => void;
    on_mobile_swipe_down: Array<(evt: TouchEvent) => void>;
    on_mobile_swipe_up: Array<(evt: TouchEvent) => void>;
    on_mobile_swipe_right: Array<(evt: TouchEvent) => void>;
    on_mobile_swipe_left: Array<(evt: TouchEvent) => void>;
    pulled: Array<() => unknown>;
    fejson: {
      pulled: number;
      instance: {
        iid: string;
        lastsync: number;
      };
      user: { username: string; id: number };
    };
  }
}
