// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

export function setJsonObj(jsonObj) {
	window.fejson = {
		instance: {
			iid: jsonObj.instance_iid,
			lastsync: jsonObj.instance_lastsync,
		},
		pulled: jsonObj.pulled,
		user: {
			id: jsonObj.user_id,
			username: jsonObj.user_username,
			email: jsonObj.user_email,
		},
	};
}

export function getJsonObj() {
	if (!window.fejson) {
		return {
			instance_iid: -1,
			instance_lastsync: -1,
			pulled: -1,
			user_id: -1,
			user_username: "unset",
			user_email: "unset",
		};
	}
	return {
		instance_iid: window.fejson.instance.iid,
		instance_lastsync: window.fejson.instance.lastsync,
		pulled: window.fejson.pulled,
		user_id: window.fejson.user.id,
		user_username: window.fejson.user.username,
		user_email: window.fejson.user.email,
	};
}

export function dateToTimestamp() {
	return Number.parseInt(Date.now());
}
