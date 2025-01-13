export function postfoldout() {
	window.dragEditor = (e) => {
		e.preventDefault();
		window.editorposition3 = e.clientX;
		window.editorposition4 = e.clientY;
		document.onmouseup = window.stopEditorDragging;
		document.onmousemove = window.editorDrag;
	};
	window.editorDrag = (e) => {
		e.preventDefault();
		const divPostEditor = document.querySelector("div#posteditor");
		divPostEditor.style.width = "70VH";
		divPostEditor.style.height = "calc(50VW - 30VH)";
		divPostEditor.style.position = "";
		divPostEditor.style.marginTop = "";
		divPostEditor.style.marginBottom = "";
		divPostEditor.style.marginLeft = "";
		divPostEditor.style.marginRight = "";

		window.editorposition1 = window.editorposition3 - e.clientX;
		window.editorposition2 = (() => {
			const o = window.editorposition4 - e.clientY;
			if (divPostEditor.offsetTop - o < 20) {
				return divPostEditor.offsetTop - 40;
			}
			return o;
		})();
		window.editorposition3 = e.clientX;
		window.editorposition4 = e.clientY;
		divPostEditor.style.top = `${
			divPostEditor.offsetTop - window.editorposition2
		}px`;
		divPostEditor.style.left = `${
			divPostEditor.offsetLeft - window.editorposition1
		}px`;
	};

	window.stopEditorDragging = () => {
		document.onmouseup = null;
		document.onmousemove = null;
	};
	document
		.getElementById("editorwindowh")
		.addEventListener("mousedown", window.dragEditor);
	window.editorFullScreenMode = (e) => {
		e.preventDefault();
		const divPostEditor = document.querySelector("div#posteditor");
		divPostEditor.style.width = "95VW";
		divPostEditor.style.height = "85VH";
		divPostEditor.style.position = "fixed";
		divPostEditor.style.marginTop = "auto";
		divPostEditor.style.marginBottom = "auto";
		divPostEditor.style.marginLeft = "auto";
		divPostEditor.style.marginRight = "auto";
		divPostEditor.style.top = "60px";
		divPostEditor.style.bottom = "0";
		divPostEditor.style.left = "0";
		divPostEditor.style.right = "0";
	};
	document
		.getElementById("editorwindowh")
		.addEventListener("dblclick", window.editorFullScreenMode);
	document.body.dataset.editorOpen = "true";
}
export function switcheditormode(elm, renderMarkdownShort, renderMarkdownLong) {
	const activeElement = document.activeElement;
	const modenames = ["short", "long", "embed"];
	const desiredmode = elm.dataset.modeOpener;
	for (const modename of modenames) {
		const opener = document.querySelector(
			`nav#editormodepicker [data-mode-opener="${modename}"]`,
		);
		const field = document.querySelector(
			`div#editorwindowm [data-mode-field="${modename}"]`,
		);

		if (modename === desiredmode) {
			opener.className =
				"editor-switcher flex items-center justify-center p-0 bg-orange-100 border-2 border-b-0 rounded-md rounded-b-none cursor-default border-emerald-600 dark:text-orange-100 dark:bg-neutral-800 text-brown-800 dark:border-zinc-400";
			field.classList.add("block");
			field.classList.remove("hidden");
		} else {
			opener.className =
				"editor-switcher flex items-center justify-center p-0 border-2 rounded-md cursor-pointer bg-emerald-200 dark:bg-teal-800 border-emerald-600 dark:text-orange-100 hover:text-white hover:bg-gray-700 text-brown-800 dark:border-zinc-400";
			field.classList.add("hidden");
			field.classList.remove("block");
		}
	}
	switch (desiredmode) {
		case "short":
			{
				document
					.getElementById("editor-short-input")
					.addEventListener("change", renderMarkdownShort);
				setInterval(renderMarkdownShort, 400);
				renderMarkdownShort();

				document.addEventListener("keydown", (ev) => {
					if (
						ev.key === "Enter" &&
						activeElement ===
							document.getElementById("editor-short-container")
					) {
						document.getElementById("editor-short-input").focus();
					} else if (
						ev.key === "Escape" &&
						activeElement ===
							document.getElementById("editor-short-input")
					) {
						activeElement.blur();
					}
				});

				document
					.getElementById("editor-short-container")
					.addEventListener("click", () => {
						document.getElementById("editor-short-input").focus();
					});
				document.getElementById("editor-short-input").focus();
			}
			break;
		case "long":
			{
				document
					.getElementById("editor-long-input")
					.addEventListener("change", renderMarkdownLong);
				renderMarkdownLong();

				document.addEventListener("keydown", (ev) => {
					if (
						ev.key === "Enter" &&
						activeElement ===
							document.getElementById("editor-long-container")
					) {
						document.getElementById("editor-long-input").focus();
					} else if (
						ev.key === "Escape" &&
						activeElement ===
							document.getElementById("editor-long-input")
					) {
						activeElement.blur();
					}
				});

				document
					.getElementById("editor-long-container")
					.addEventListener("click", () => {
						document.getElementById("editor-long-input").focus();
					});
				document.getElementById("editor-long-input").focus();
			}
			break;
		default:
			break;
	}
}
