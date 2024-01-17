import { mount } from '../react/query-builder';

export default {
    mounted() {
        this.handleRefreshData = () => {
            this.pushEventTo(this.el, "load-query", {}, (reply, _ref) => {
                if (this.root) {
                    this.root.unmount();
                }
                this.root = mount(this.el, {
                    initialQuery: reply.query,
                    fields: reply.fields,
                    queryChange: (q) => { this.queryChange(q) }
                });
            })
        };

        window.addEventListener("phx:query-builder:refresh", this.handleRefreshData)

        this.handleRefreshData();
    },
    queryChange(q) {
        if (this.previousQuery === JSON.stringify(q)) {
            return;
        }
        this.previousQuery = JSON.stringify(q);
        this.pushEventTo(this.el, 'query-changed', { q });
    },
    destroyed() {
        if (this.root) {
            this.root.unmount();
        }
        window.removeEventListener("phx:query-builder:refresh", this.handleRefreshData)
    }
};
