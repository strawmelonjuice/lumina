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
let fejson= {};

setInterval(pulls, 30000);
window.pulled = [
    () => {
        for (const a of document.getElementsByClassName("ownuserprofilelink")) {
            a.setAttribute("href", `/user/${fejson.user.username}/me`);
        }
    },
];

function putpulls () {
    pulled.forEach((o) => {
        o();
    });
}

setTimeout(function () {
    setInterval(putpulls);
}, 80);
// Turns GET params into an object.
function getParams () {
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
function pulls () {
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
pulls()


