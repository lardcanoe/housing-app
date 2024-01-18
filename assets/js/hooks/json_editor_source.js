export default {
    updated() {
        try {
            let editor = window.json_editors[this.el.getAttribute("data-editor-id")];
            if (editor.getMode() === "tree") {
                editor.update(JSON.parse(this.el.value));
            } else {
                if (editor.get() !== JSON.parse(this.el.value)) {
                    editor.setText(this.el.value);
                } else {
                }
            }
        } catch (_e) { }
    },
}
