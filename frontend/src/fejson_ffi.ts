/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 *
 */

export function setJsonObj(jsonObj: {
	instance_iid: string;
	instance_lastsync: number;
	pulled: number;
	user_id: number;
	user_username: string;
	user_email: string;
}) {
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
			pulled: 0,
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

export function dateToTimestamp(): number {
	return Date.now();
}

const MAX_QUEUE_SIZE = 1000;

export function queueFejsonFunction(func: () => null) {
	if (!window.fejsonqueue) {
		window.fejsonqueue = [];
	}
	if (window.fejsonqueue.length >= MAX_QUEUE_SIZE) {
		console.warn("Function queue size limit reached");
		return;
	}
	window.fejsonqueue.push(func);
}

export function getQueuedFejsonFunctions(): Array<() => null> {
	return window.fejsonqueue || [];
}

interface fejsonObject {
	pulled: number;
	instance: {
		iid: string;
		lastsync: number;
	};
	user: { username: string; id: number; email: string };
}
declare global {
	export interface Window {
		mobileMenuToggle: () => null;
		on_mobile_swipe_down: Array<(evt: TouchEvent) => null>;
		on_mobile_swipe_up: Array<(evt: TouchEvent) => null>;
		on_mobile_swipe_right: Array<(evt: TouchEvent) => null>;
		on_mobile_swipe_left: Array<(evt: TouchEvent) => null>;
		fejsonqueue: Array<() => null>;
		fejson: fejsonObject;
	}
}
