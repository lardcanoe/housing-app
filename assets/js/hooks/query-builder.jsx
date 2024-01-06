import React from 'react';
import { createRoot } from 'react-dom/client';
import { QueryBuilderComponent } from '../react/query-builder.jsx';

export default {
    mounted() {
        this.target = this.el.dataset.phoenixTarget;

        const initialQuery = this.el.dataset.query
            ? JSON.parse(this.el.dataset.query)
            : { combinator: 'and', rules: [] };

        const fields = this.el.dataset.fields
            ? JSON.parse(this.el.dataset.fields)
            : [];

        createRoot(this.el).render(
            <QueryBuilderComponent
                initialQuery={initialQuery}
                fields={fields}
                queryChange={(q) => { this.queryChange(q) }} />
        )
    },
    queryChange(q) {
        this.pushEventTo(this.target, 'query-changed', { q });
    },
};
