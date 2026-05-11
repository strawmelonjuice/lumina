/*
 * Lumina/Peonies
 * Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors.
 *
 * This software is licensed under the European Union Public Licence (EUPL) v1.2.
 * You may not use this work except in compliance with the Licence.
 * You may obtain a copy of the Licence at: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
 *
 * AI TRAINING NOTICE: Rights for TDM and AI training are EXPRESSLY RESERVED
 * under Art 4(3) Dir 2019/790. AI training constitutes a Derivative Work.
 * See LICENSE file in the repository root for full details.
 *
 *
 * This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND.
 * See the Licence for the specific language governing permissions and limitations.
 */

import { Result$Ok, Result$Error } from '../../gleam.mjs';

let lumina_connection;
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 5;

/**
 * Creates and manages the self-restoring websocket connection.
 * Stored in window to keep Gleam pure and handle browser-level crashes safely.
 *
 * @returns {{type: "Ok", value: null} | {type: "Error", value: null}} Gleam Result format
 */
export function createSelfRestoringWebsocket() {
	// Guard clause for server-side rendering environments
	if (typeof window === 'undefined' || typeof document === 'undefined') {
		return { type: "Error", value: null };
	}

	try {
		connectWebSocket();
		return { type: "Ok", value: null };
	} catch (error) {
		console.error("Failed to initialize websocket infrastructure:", error);
		return { type: "Error", value: null };
	}
}

/**
 * Internal function to handle connection and lifecycle hooks
 */
function connectWebSocket(cb) {
	const ws = new WebSocket(`ws://${window.location.host}/connection`);

	// Attach to window so JS can access it globally for sending data
	lumina_connection = ws;

	ws.onopen = () => {
		console.log("⚡ Lumina connected to backend.");
		reconnectAttempts = 0;
		removeReconnectionModal();
	};

	ws.onmessage = (event) => {

	};

	ws.onclose = (event) => {
		console.warn(`🔌 WebSocket closed. Code: ${event.code}. Attempting recovery...`);
		handleDisconnect();
	};

	ws.onerror = (error) => {
		console.error("❌ WebSocket error:", error);
	};
}

/**
 * Handles the recovery logic when a disconnect occurs
 */
function handleDisconnect() {
	if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
		reconnectAttempts++;
		showReconnectionModal();

		// Exponential backoff or simple delay (e.g., 3 seconds)
		setTimeout(() => {
			connectWebSocket();
		}, 3000);
	} else {
		crashScreen();
	}
}


/**
 * Injects a DaisyUI modal over the #app container without removing it yet
 */
function showReconnectionModal() {
	if (document.getElementById('lumina-reconnect-modal')) return;

	const appContainer = document.querySelector('#app');
	if (!appContainer) return;

	// Ensure the app container can host an absolute/fixed modal over it safely
	if (getComputedStyle(appContainer).position === 'static') {
		appContainer.style.position = 'relative';
	}

	const modalHtml = `
    <div id="lumina-reconnect-modal" class="absolute inset-0 bg-base-300/70 backdrop-blur-sm z-50 flex items-center justify-center animate-fade-in">
      <div class="modal-box border border-warning/20 bg-base-100 shadow-2xl text-center max-w-sm">
        <h3 class="text-lg font-bold text-warning flex items-center justify-center gap-2">
          <span class="loading loading-spinner loading-md"></span>
          Connection Lost
        </h3>
        <p class="py-4 text-sm text-base-content/70">
          Attempting to reconnect to the Lumina servers...<br>
          <span class="badge badge-neutral mt-2">Attempt ${reconnectAttempts} of ${MAX_RECONNECT_ATTEMPTS}</span>
        </p>
      </div>
    </div>
  `;

	appContainer.insertAdjacentHTML('beforeend', modalHtml);
}

/**
 * Removes the DaisyUI modal once connection is restored
 */
function removeReconnectionModal() {
	const modal = document.getElementById('lumina-reconnect-modal');
	if (modal) modal.remove();
}


function crashScreen() {
	console.error("Fatality encountered, crashing the runtime.");

	document.body.innerHTML = `
    <div class="hero min-h-screen bg-base-200 text-base-content font-sans antialiased">
      <div class="hero-content text-center">
        <div class="max-w-md card bg-base-100 shadow-xl border border-error/30 p-8">
          <div class="avatar placeholder flex justify-center mb-4">
            <div class="bg-error text-error-content rounded-full w-16 h-16">
              <span class="text-2xl font-bold">!</span>
            </div>
          </div>
          <h1 class="text-3xl font-extrabold text-error tracking-tight">Session Crashed</h1>
          <p class="py-4 text-sm text-base-content/80">
            Lumina lost its secure connection to the backend pipeline, and all automated recovery attempts failed.
          </p>
          <div class="divider my-1"></div>
          <p class="text-xs text-base-content/50 mb-6 font-mono bg-base-300 p-2 rounded">
            ERR_CONNECTION_REFUSED_FATAL
          </p>
          <button onclick="window.location.reload();" class="btn btn-error btn-block gap-2 shadow-lg">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99" />
            </svg>
            Reload Application
          </button>
        </div>
      </div>
    </div>
  `;
}

/**
 * A utility helper function to send messages through the global connection.
 * Can be mapped to a Gleam external function if needed.
 *
 * @param {string} jsonPayload
 * @returns {boolean} Success status
 */
export function sendWebSocketMessage(jsonPayload) {
	if (lumina_connection && lumina_connection.readyState === WebSocket.OPEN) {
		lumina_connection.send(jsonPayload);
		return true;
	}
	console.error("Cannot send message. WebSocket is not open.");
	return false;
}
