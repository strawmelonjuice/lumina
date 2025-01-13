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
        const divPostEditor = (
            document.querySelector("div#posteditor")
        );
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
        const divPostEditor = (
            document.querySelector("div#posteditor")
        );
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