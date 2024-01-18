export default {
    mounted() {
        const inputId = this.el.getAttribute("data-input-id");
        const hook = this;

        this.editor = new JSONEditor(
            this.el,
            {
                onChangeText: (json) => {
                    const target = document.getElementById(inputId);
                    try {
                        JSON.parse(json);
                        target.value = json;
                        target.dispatchEvent(new Event("change", { bubbles: true }));
                    } catch (_e) { }
                },
                onChange: () => {
                    try {
                        const target = document.getElementById(inputId);
                        json = hook.editor.get();

                        target.value = JSON.stringify(json);
                        target.dispatchEvent(new Event("change", { bubbles: true }));
                    } catch (_e) { }
                },
                onModeChange: (newMode) => {
                    hook.mode = newMode;
                },
                modes: ["code", "tree", "form"]
            },
            JSON.parse(document.getElementById(inputId).value)
        );

        window.json_editors[this.el.id] = this.editor;
    },
}
