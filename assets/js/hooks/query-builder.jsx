import { mount } from '../react/query-builder';

export default {
    mounted() {
        this.updated();
    },
    updated() {
        const initialQuery = this.el.dataset.query
            ? JSON.parse(this.el.dataset.query)
            : { combinator: 'and', rules: [] };

        const fields = this.el.dataset.fields
            ? JSON.parse(this.el.dataset.fields)
            : [];

        // FUTURE: THIS IS A COMPLETE HACK TO MAKE IT REFRESH!
        if (this.root) {
            this.root.unmount();
        }

        this.root = mount(this.el, {
            initialQuery: initialQuery,
            fields: fields,
            queryChange: (q) => { this.queryChange(q) }
        })
    },
    queryChange(q) {
        this.pushEventTo(this.el, 'query-changed', { q });
    },
    destroyed() {
        if (this.root) {
            this.root.unmount();
        }
    }
};
