import { JSONEditor } from "../../vendor/jsoneditor";
JSONEditor.defaults.options.theme = "tailwind";

export default {
    mounted() {
        this.pushEvent("load-schema", {}, (reply, ref) => {
            const editor = new JSONEditor(this.el, {
                schema: reply.schema,
                disable_collapse: true,
                disable_edit_json: true,
                disable_properties: true,
                ajax_cache_buster: true,
                display_required_only: false,
                startval: reply.data
            });

            document
                .getElementById("json-schema-form-submit")
                .addEventListener("click", () => {
                    const errors = editor.validate();
                    if (errors.length) {
                        editor.setOption("show_errors", "always");
                    } else {
                        editor.setOption("show_errors", "interaction");
                        this.pushEvent("submit", editor.getValue());
                    }
                });
        });
    },
};
