import { mount } from '../react/query-builder';

export default {
    mounted() {
        this.target = this.el.dataset.phoenixTarget;

        const initialQuery = this.el.dataset.query
            ? JSON.parse(this.el.dataset.query)
            : { combinator: 'and', rules: [] };

        const fields = this.el.dataset.fields
            ? JSON.parse(this.el.dataset.fields)
            : [];

        this.unmountComponent = mount(this.el, {
            initialQuery: initialQuery,
            fields: fields,
            queryChange: (q) => { this.queryChange(q) }
        })
    },
    queryChange(q) {
        this.pushEventTo(this.target, 'query-changed', { q });
    },
    destryed() {
        if (this.unmountComponent) {
            this.unmountComponent(this.el);
        }
    }
};
