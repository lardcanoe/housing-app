export default {
    updated() {
        const json = JSON.parse(this.el.getAttribute("data-json"));
        this.editor = new JSONEditor(
            this.el,
            {
                mode: "preview",
            },
            json
        );
    },
    mounted() {
        const json = JSON.parse(this.el.getAttribute("data-json"));
        this.editor = new JSONEditor(
            this.el,
            {
                mode: "preview",
            },
            json
        );
    },
}
