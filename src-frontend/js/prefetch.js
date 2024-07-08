/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

/**
 * @description These variables are passed down from the server.
 * @global
 * @type {{ instance: { config: { interinstance: { iid: string; lastsync: number; }; }; }; user: { username: string; id: number; }; }}
 */
let fejson = {
    instance: {config: {interinstance: {iid: "", lastsync: 0}}},
    user: {username: "", id: 0},
};

setInterval(pulls, 30000);
window.pulled = [
    () => {
        for (const a of document.getElementsByClassName("ownuseravatarsrc")) {
            if (a.getAttribute("src") === "") {
                a.setAttribute("src", `/user/avatar/${fejson.user.id}`);
            }
        }
    },
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
 * description placeholder
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
 * description placeholder
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
        wordslast,
    )}${Math.floor(Math.random() * 10001) + 1000}`.replace("--", "-");
}

window.onload = () => {
    window.mobileMenuToggle = () => {
        const mobilemenu = document.getElementById("mobile-menu");
        if (mobilemenu.classList.contains("hidden")) {
            mobilemenu.classList.remove("hidden");
            document
                .getElementById("btn-mobile-menu-open")
                .classList.add("hidden");
            document
                .getElementById("btn-mobile-menu-close")
                .classList.remove("hidden");
        } else {
            mobilemenu.classList.add("hidden");
            document
                .getElementById("btn-mobile-menu-open")
                .classList.remove("hidden");
            document
                .getElementById("btn-mobile-menu-close")
                .classList.add("hidden");
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
    document
        .getElementsByTagName("main")[0]
        .addEventListener("touchstart", handleTouchStart, false);
    document
        .getElementsByTagName("main")[0]
        .addEventListener("touchmove", handleTouchMove, false);
}, 300);

let xDown = null;
let yDown = null;

function getTouches(evt) {
    return (
        evt.touches || // browser API
        evt.originalEvent.touches
    ); // jQuery (I love jquery, so Lumina might get it)
}

function handleTouchStart(evt) {
    const firstTouch = getTouches(evt)[0];
    xDown = firstTouch.clientX;
    yDown = firstTouch.clientY;
}

function handleTouchMove(evt) {
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
                for (fn of window.on_mobile_swipe_left) {
                    fn(evt);
                }
            }
        } else {
            if (window.matchMedia("(max-width: 1024px)").matches) {
                for (fn of window.on_mobile_swipe_right) {
                    fn(evt);
                }
            }
        }
    } else {
        if (yDiff > 0) {
            if (window.matchMedia("(max-width: 1024px)").matches) {
                for (fn of window.on_mobile_swipe_up) {
                    fn(evt);
                }
            }
        } else {
            if (window.matchMedia("(max-width: 1024px)").matches) {
                for (fn of window.on_mobile_swipe_down) {
                    fn(evt);
                }
            }
        }
    }
    /* reset values */
    xDown = null;
    yDown = null;
}
